pragma solidity ^0.8.0;

import {ERC721AQueryable, ERC721A, IERC721A} from "ERC721A/extensions/ERC721AQueryable.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SynthiaCustomTraits} from "../SynthiaCustomTraits.sol";
import {SynthiaRenderer} from "../SynthiaRenderer.sol";

contract FreeForHolders is Owned {
    error NotSynthiaOwner();

    address synthia;
    address synthiaCustomTraits;
    address renderer;
    uint256 itemId;

    constructor(address _synthia, address _synthiaCustomTraits, address _renderer, uint256 _itemId) Owned(msg.sender) {
        synthia = _synthia;
        synthiaCustomTraits = _synthiaCustomTraits;
        renderer = _renderer;
        itemId = _itemId;
    }

    modifier checkSynthiaOwnership() {
        if (ERC721A(synthia).balanceOf(msg.sender) == 0) {
            revert NotSynthiaOwner();
        }
        _;
    }

    function mintAndSet(uint256 synthiaTokenId) public checkSynthiaOwnership {
        SynthiaCustomTraits(synthiaCustomTraits).mintAndSetWithOverrides(
            msg.sender, itemId, synthiaTokenId, SynthiaRenderer(renderer).flipBit(0, 1)
        );
    }

    function mint() public checkSynthiaOwnership {
        SynthiaCustomTraits(synthiaCustomTraits).mint(msg.sender, itemId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

pragma solidity ^0.8.0;

import {ERC721AQueryable, ERC721A, IERC721A} from "ERC721A/extensions/ERC721AQueryable.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {ISynthiaTraitsERC721} from "./ISynthiaTraitsERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SynthiaData} from "./SynthiaData.sol";
import {SynthiaRenderer} from "./SynthiaRenderer.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";

contract SynthiaCustomTraits is ERC721AQueryable, Owned, Initializable, ISynthiaTraitsERC721 {
    uint256 _itemId;
    address public synthiaData;
    address public synthia;
    address public synthiaRenderer;
    mapping(uint256 => ItemV1) public itemsv1;
    mapping(uint256 => uint256) public mappingTokenIdToItemId;
    mapping(address => bool) public allowedMinters;

    struct ItemV1 {
        string name;
        string image;
        string onchainImgId;
        string description;
        uint256 traitIdx;
        uint256 exists;
        address minter;
    }

    error ErrorMessage(string message);
    error NotOwner();

    constructor() ERC721A("", "") Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address _synthiaData, address _synthiaRenderer, address _synthia) public initializer {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        synthiaData = _synthiaData;
        synthiaRenderer = _synthiaRenderer;
        synthia = _synthia;
    }

    function updateMinter(address minter, bool value) public onlyOwner {
        allowedMinters[minter] = value;
    }

    function name() public pure override(IERC721A, ERC721A) returns (string memory) {
        return "Synthia Custom Traits";
    }

    function symbol() public pure override(IERC721A, ERC721A) returns (string memory) {
        return "SYNCT";
    }

    event ItemAdded(uint256 id);

    function addItem(
        string memory _name,
        string memory _image,
        string memory _onchainImgId,
        string memory _description,
        uint256 _traitIdx,
        address _minter
    ) public onlyOwner {
        uint256 id = ++_itemId;
        itemsv1[id] = ItemV1(_name, _image, _onchainImgId, _description, _traitIdx, 1, _minter);
        emit ItemAdded(id);
    }

    function mint(address to, uint256 itemId) public returns (uint256) {
        if (allowedMinters[msg.sender] != true) {
            revert ErrorMessage("Not allowed minter");
        }
        if (itemsv1[itemId].exists == 0) {
            revert ErrorMessage("Item ID does not exist");
        }
        uint256 tokenId = _nextTokenId();
        mappingTokenIdToItemId[tokenId] = itemId;
        _mint(to, 1);
        return tokenId;
    }

    modifier checkSynthiaOwnership(uint256 synthiaTokenId, address to) {
        if (to != ERC721A(synthia).ownerOf(synthiaTokenId)) {
            revert NotOwner();
        }
        _;
    }

    function mintAndSet(address to, uint256 itemId, uint256 synthiaNftId)
        public
        checkSynthiaOwnership(synthiaNftId, to)
    {
        uint256 tokenId = mint(to, itemId);
        ItemV1 memory item = itemsv1[itemId];
        SynthiaRenderer(synthiaRenderer).setCustomTrait(synthiaNftId, item.traitIdx, address(this), tokenId);
    }

    function mintAndSetWithOverrides(address to, uint256 itemId, uint256 synthiaNftId, uint256 overrides)
        public
        checkSynthiaOwnership(synthiaNftId, to)
    {
        uint256 tokenId = mint(to, itemId);
        ItemV1 memory item = itemsv1[itemId];
        SynthiaRenderer(synthiaRenderer).setCustomTraitWithOverrides(
            synthiaNftId, item.traitIdx, address(this), tokenId, overrides
        );
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"',
                        getTraitName(tokenId),
                        '","description":"',
                        itemsv1[mappingTokenIdToItemId[tokenId]].description,
                        '","image":"',
                        getTraitImage(tokenId),
                        '"}'
                    )
                )
            )
        );
    }

    function getTraitIndex(uint256 tokenId) external view returns (uint256) {
        return itemsv1[mappingTokenIdToItemId[tokenId]].traitIdx;
    }

    function getTraitName(uint256 tokenId) public view returns (string memory) {
        return itemsv1[mappingTokenIdToItemId[tokenId]].name;
    }

    function getTraitImage(uint256 tokenId) public view returns (string memory) {
        ItemV1 memory item = itemsv1[mappingTokenIdToItemId[tokenId]];
        if (keccak256(abi.encodePacked(item.onchainImgId)) != keccak256(abi.encodePacked(""))) {
            return SynthiaData(synthiaData).getData(item.onchainImgId);
        }
        return itemsv1[mappingTokenIdToItemId[tokenId]].image;
    }
}

pragma solidity ^0.8.0;

import {SSTORE2} from "solmate/utils/SSTORE2.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {Synthia, IERC721OwnerOf} from "./Synthia.sol";
import {SynthiaTraits} from "./SynthiaTraits.sol";
import {ISynthiaTraitsERC721} from "./ISynthiaTraitsERC721.sol";

contract SynthiaRenderer is Owned, Initializable {
    error ErrorMessage(string);
    // WARNING: Additional state variables should go below everything. Scroll to bottom.

    string[] public traits;
    Synthia public synthia;
    SynthiaTraits public synthiaTraits;
    mapping(string => address) public pointers;

    function _getTraitIdx(string memory name) internal view returns (uint256) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        for (uint256 i = 0; i < traits.length; i++) {
            if (keccak256(abi.encodePacked(traits[i])) == nameHash) {
                return i;
            }
        }
        revert ErrorMessage("Trait not found");
    }

    function getTraitsLength() public view returns (uint256) {
        return traits.length;
    }

    constructor() Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address _synthia, address _synthiaTraits) public initializer {
        synthia = Synthia(_synthia);
        synthiaTraits = SynthiaTraits(_synthiaTraits);
        traits = ["clothes", "hair", "accessory", "hat"];
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    mapping(address => bool) public traitAdmin;

    function updateTraitAdmin(address traitAdminAddr, bool value) public onlyOwner {
        traitAdmin[traitAdminAddr] = value;
    }

    modifier onlyTraitAdmin() {
        if (!traitAdmin[msg.sender]) {
            revert ErrorMessage("Not trait admin");
        }
        _;
    }

    function addPointer(string memory name, string calldata data) public onlyOwner {
        if (pointers[name] != address(0)) {
            revert ErrorMessage("Pointer exists");
        }
        pointers[name] = SSTORE2.write(bytes(data));
    }

    function getData(string memory name) public view returns (string memory) {
        return string(SSTORE2.read(pointers[name]));
    }

    function getSvgString() public view returns (string memory) {}

    struct FilterId {
        string hair;
        string clothes;
        string hat;
        string acc;
        string shaman;
    }

    function _getFilterIds() internal pure returns (FilterId memory filters) {
        return FilterId({hair: "hf", clothes: "cf", hat: "htf", acc: "accf", shaman: "sf"});
    }

    function _getFilter(string memory id, string memory color) internal pure returns (string memory) {
        return string.concat(
            '<filter id="',
            id,
            '"><feFlood flood-color="',
            color,
            '" result="overlayColor" /><feComposite operator="in" in="overlayColor" in2="SourceAlpha" result="coloredAlpha" /><feBlend mode="overlay" in="coloredAlpha" in2="SourceGraphic" /></filter>'
        );
    }

    function _getImageDef(string memory data, string memory id) internal pure returns (string memory) {
        return string.concat('<image href="', data, '" id="', id, '"></image>');
    }

    function _getSvgFilters(Colors memory colors) internal view returns (string memory) {
        FilterId memory filters = _getFilterIds();
        return string.concat(
            _getFilter(filters.shaman, "#00cbdd"),
            _getFilter(filters.hair, colors.hair),
            _getFilter(filters.clothes, colors.clothes),
            _getFilter(filters.hat, colors.hat),
            _getFilter(filters.acc, colors.acc)
        );
    }

    function getMultipleSeeds(uint256 initialSeed, uint8 numSeeds) public pure returns (uint256[] memory seeds) {
        seeds = new uint[](numSeeds);

        for (uint8 i = 0; i < numSeeds; i++) {
            uint256 shiftedSeed = (initialSeed >> i) | (initialSeed << (256 - i));
            seeds[i] = uint256(keccak256(abi.encode(shiftedSeed)));
        }
    }

    function _getHairMask(
        bool hasHat,
        uint256 x,
        uint256 y,
        uint256 clothesX,
        uint256 clothesY,
        uint256 hairX,
        uint256 hairY
    ) internal pure returns (string memory) {
        uint256 bottomY;
        if (y == 0) {
            if (x == 0) bottomY = 200;
            if (x == 1) bottomY = 200;
            if (x == 3) bottomY = 207;
            if (x == 4) bottomY = 184;
        }

        if (y == 1) {
            if (x == 0 || x == 2) {
                bottomY = 279;
            }
        }

        if (y == 2) {
            if (x == 1) bottomY = 140;
        }
        if (y == 3) {
            if (x == 4) bottomY = 200;
            if (x == 1) bottomY = 286;
            if (x == 2) bottomY = 345;
        }
        if (y == 4) {
            if (x == 4) bottomY = 167;
        }
        if (y == 5) {
            if (x == 0) bottomY = 259;
            if (x == 1) bottomY = 261;
            if (x == 2) bottomY = 261;
            if (x == 4) bottomY = 206;
        }
        if (!hasHat) {
            bottomY = 0;
        }
        if (
            (bottomY != 0 && hairY == 3 && hairX == 4) || (y == 4 && x == 1) || clothesY == 2 && clothesX == 3
                || clothesY == 3 && clothesX == 4
        ) {
            return '<clipPath id="hcp"><rect x="0" y="0" height="0" width="0" /></clipPath>';
        }
        if (bottomY == 0) return "";
        return string.concat(
            '<clipPath id="hcp"><rect x="0" y="',
            Strings.toString(bottomY),
            '" height="100%" width="100%" /></clipPath>'
        );
    }

    function _getDefs(
        Colors memory colors,
        bool hasHat,
        uint256 hatX,
        uint256 hatY,
        uint256 clothesX,
        uint256 clothesY,
        uint256 hairX,
        uint256 hairY
    ) internal view returns (string memory) {
        return string.concat(
            "<defs>",
            _getSvgFilters(colors),
            '<clipPath id="c"><rect width="400" height="400" /></clipPath>',
            _getImageDef(getData("body"), "bimg"),
            _getImageDef(getData("clothes"), "cimg"),
            _getImageDef(getData("hair"), "himg"),
            _getImageDef(getData("hat"), "htimg"),
            _getImageDef(getData("accessory"), "acimg"),
            _getHairMask(hasHat, hatX, hatY, clothesX, clothesY, hairX, hairY),
            "</defs>"
        );
    }

    function _chance(uint256 percent, uint256 seed) internal pure returns (bool) {
        return _randomNumberBetween(1, 100, seed) <= percent;
    }

    function _randomNumberBetween(uint256 start, uint256 end, uint256 seed) internal pure returns (uint256) {
        uint256 range = end - start + 1;
        uint256 randomNumber = start + (seed % range);

        return randomNumber;
    }

    function _getX(uint256 seed) internal pure returns (uint256) {
        return _randomNumberBetween(0, 4, seed);
    }

    function _getY(uint256 seed) internal pure returns (uint256) {
        return _randomNumberBetween(0, 5, seed);
    }

    struct Pos {
        uint256 bodyX;
        uint256 clothesX;
        uint256 clothesY;
        uint256 hairX;
        uint256 hairY;
        uint256 hatX;
        uint256 hatY;
        uint256 accX;
        uint256 accY;
    }

    struct Colors {
        string bg;
        string clothes;
        string hat;
        string hair;
        string acc;
    }

    struct TraitInfo {
        string factionName;
        uint256 factionIdx;
        uint256 intelligence;
        uint256 agility;
        uint256 charisma;
        uint256 wisdom;
        uint256 strength;
        uint256 technomancy;
        bool hasHair;
        bool hasAccessory;
        bool hasHat;
        bool hasCustomClothes;
        bool hasCustomHair;
        bool hasCustomAccessory;
        bool hasCustomHat;
        bool canBeHybrid;
    }

    function _getTraitType(string memory name, string memory value, bool custom, bool comma)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"trait_type":"', name, custom ? " [CUSTOM]" : "", '","value":"', value, '"}', comma ? "," : ""
        );
    }

    function _getStatType(string memory name, uint256 value, bool comma) internal pure returns (string memory) {
        return string.concat('{"trait_type":"', name, '","value":', Strings.toString(value), "}", comma ? "," : "");
    }

    function _getCustomTraitName(uint256 tokenId, uint256 idx) internal view returns (string memory) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];
        try ISynthiaTraitsERC721(trait.contractAddress).getTraitName(trait.tokenId) returns (string memory traitName) {
            return traitName;
        } catch {
            return "";
        }
    }

    function _getStats(TraitInfo memory traitInfo) internal pure returns (string memory) {
        return string.concat(
            _getStatType("Intelligence", traitInfo.intelligence, true),
            _getStatType("Agility", traitInfo.agility, true),
            _getStatType("Strength", traitInfo.strength, true),
            _getStatType("Charisma", traitInfo.charisma, true),
            _getStatType("Wisdom", traitInfo.wisdom, true),
            _getStatType("Technomancy", traitInfo.technomancy, true)
        );
    }

    function _getAttrs(uint256 tokenId, Pos memory pos, TraitInfo memory traitInfo)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            "[",
            _getStats(traitInfo),
            traitInfo.hasHat
                ? _getTraitType(
                    "hat",
                    traitInfo.hasCustomHat
                        ? _getCustomTraitName(tokenId, _getTraitIdx("hat"))
                        : synthiaTraits.getHatName(uint16(pos.hatX), uint16(pos.hatY)),
                    traitInfo.hasCustomHat,
                    true
                )
                : "",
            traitInfo.hasAccessory
                ? _getTraitType(
                    "accessory",
                    traitInfo.hasCustomAccessory
                        ? _getCustomTraitName(tokenId, _getTraitIdx("accessory"))
                        : synthiaTraits.getAccesoryName(uint16(pos.accX), uint16(pos.accY)),
                    traitInfo.hasCustomAccessory,
                    true
                )
                : "",
            traitInfo.hasHair
                ? _getTraitType(
                    "hair",
                    traitInfo.hasCustomHair
                        ? _getCustomTraitName(tokenId, _getTraitIdx("hair"))
                        : synthiaTraits.getHairName(uint16(pos.hairX), uint16(pos.hairY)),
                    traitInfo.hasCustomHair,
                    true
                )
                : "",
            _getTraitType("faction", traitInfo.factionName, false, true),
            _getTraitType(
                "clothes",
                traitInfo.hasCustomClothes
                    ? _getCustomTraitName(tokenId, _getTraitIdx("clothes"))
                    : synthiaTraits.getClothesName(uint16(pos.clothesX), uint16(pos.clothesY)),
                traitInfo.hasCustomClothes,
                false
            ),
            "]"
        );
    }

    function getPrerevealMetadataUri() public pure returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    '{"name":"Synthia Virtual Identity Bootloader","description":"Loading...","image":"https://lpmetadata.s3.us-west-1.amazonaws.com/bootloader.gif"}'
                )
            )
        );
    }

    function getMetadataDataUri(uint256 seed, uint256 tokenId) public view returns (string memory) {
        seed = uint256(keccak256(abi.encode(synthia.seed(), tokenId)));
        uint256[] memory seeds = getMultipleSeeds(seed, 25);
        TraitInfo memory traitInfo = getTraitInfo(seeds, tokenId);
        Pos memory pos = _getPos(seeds, traitInfo.factionIdx);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"Synthia Identity #',
                        Strings.toString(tokenId),
                        '","image":"',
                        string.concat(
                            "data:image/svg+xml;base64,",
                            Base64.encode(bytes(_getSvg(tokenId, traitInfo, pos, _getColors(seeds))))
                        ),
                        '","attributes":',
                        _getAttrs(tokenId, pos, traitInfo),
                        ',"description":"',
                        synthiaTraits.getDescription(),
                        '"}'
                    )
                )
            )
        );
    }

    struct Overrides {
        bool clothes;
        bool hair;
        bool accessory;
        bool hat;
    }

    function _getSvg(uint256 tokenId, TraitInfo memory traitInfo, Pos memory pos, Colors memory colors)
        internal
        view
        returns (string memory)
    {
        FilterId memory filters = _getFilterIds();
        uint32 clothesTrait = synthiaTraits.packXY(uint16(pos.clothesX), uint16(pos.clothesY));

        bool isHood =
            clothesTrait == 131072 || clothesTrait == 262145 || clothesTrait == 196610 || clothesTrait == 262147;
        string memory clothes = _getTraitString(filters.clothes, "cimg", pos.clothesX, pos.clothesY);

        Overrides memory overrides = Overrides(
            checkBit(tokenIdOverrides[tokenId], 0),
            checkBit(tokenIdOverrides[tokenId], 1),
            checkBit(tokenIdOverrides[tokenId], 2),
            checkBit(tokenIdOverrides[tokenId], 3)
        );

        return _constructSvg(SvgParameters(tokenId, traitInfo, pos, colors, isHood, clothes, filters, overrides));
    }

    function _getFactionArr() internal view returns (string[6] memory) {
        return ["Neo-Luddites", "Data Syndicate", "Techno Shamans", "The Grid", "The Reclaimed", "The Disconnected"];
    }

    function getTraitInfo(uint256[] memory seeds, uint256 tokenId) public view returns (TraitInfo memory) {
        string[6] memory factions = _getFactionArr();
        uint256 factionIdx = _randomNumberBetween(0, factions.length - 1, seeds[17]);
        return TraitInfo({
            factionName: factions[factionIdx],
            factionIdx: factionIdx,
            hasHair: _chance(90, seeds[0]),
            hasAccessory: _chance(50, seeds[1]),
            hasHat: _chance(50, seeds[2]),
            hasCustomClothes: hasCustomTrait(tokenId, 0),
            hasCustomHair: hasCustomTrait(tokenId, 1),
            hasCustomAccessory: hasCustomTrait(tokenId, 2),
            hasCustomHat: hasCustomTrait(tokenId, 3),
            canBeHybrid: factionIdx == 2 ? _chance(5, seeds[18]) : false,
            intelligence: _randomNumberBetween(1, 100, seeds[19]),
            agility: _randomNumberBetween(1, 100, seeds[20]),
            charisma: _randomNumberBetween(1, 100, seeds[21]),
            wisdom: _randomNumberBetween(1, 100, seeds[22]),
            technomancy: _randomNumberBetween(1, 100, seeds[23]),
            strength: _randomNumberBetween(1, 100, seeds[24])
        });
    }

    function _getPos(uint256[] memory seeds, uint256 factionIdx) internal pure returns (Pos memory) {
        return Pos({
            // If faction is techno shaman then allow for transcendence
            bodyX: _randomNumberBetween(0, factionIdx == 2 ? 3 : 2, seeds[16]),
            clothesX: _getX(seeds[3]),
            // Neo-luddites only wear neo luddite clothes
            clothesY: factionIdx == 0 ? 0 : _getY(seeds[4]),
            hairX: _getX(seeds[5]),
            hairY: _getY(seeds[6]),
            hatX: _getX(seeds[7]),
            hatY: factionIdx == 0 ? 0 : _getY(seeds[8]),
            accX: _getX(seeds[9]),
            accY: factionIdx == 0 ? 0 : _getY(seeds[10])
        });
    }

    function _getColorArrays() internal pure returns (string[6] memory, string[8] memory) {
        string[6] memory bgColors = ["#FF2079", "#28fcb3", "#1C1C1C", "#7122FA", "#FDBC3B", "#1ba6fe"];
        string[8] memory traitColors = [
            // Blue
            "#0039f3",
            // magenta
            "#d400f3",
            // brown
            "#4b2d15",
            // lime
            "#4de245",
            // cyan
            "#45e2d9",
            // gold
            "#ffd325",
            // light blue
            "#7baaf6",
            // gray
            "#919191"
        ];
        return (bgColors, traitColors);
    }

    function _getColors(uint256[] memory seeds) internal view returns (Colors memory) {
        (string[6] memory bgColors, string[8] memory traitColors) = _getColorArrays();
        return Colors({
            bg: bgColors[_randomNumberBetween(0, bgColors.length - 1, seeds[11])],
            clothes: traitColors[_randomNumberBetween(0, traitColors.length - 1, seeds[12])],
            hat: traitColors[_randomNumberBetween(0, traitColors.length - 1, seeds[13])],
            hair: traitColors[_randomNumberBetween(0, traitColors.length - 1, seeds[14])],
            acc: traitColors[_randomNumberBetween(0, traitColors.length - 1, seeds[15])]
        });
    }

    // Define a new struct to group related parameters.
    struct SvgParameters {
        uint256 tokenId;
        TraitInfo traitInfo;
        Pos pos;
        Colors colors;
        bool isHood;
        string clothes;
        FilterId filters;
        Overrides overrides;
    }

    function _constructSvg(SvgParameters memory params) internal view returns (string memory) {
        string memory accessory = params.traitInfo.hasCustomAccessory
            ? _getCustomTraitSvgString(params.tokenId, 2)
            : params.traitInfo.hasAccessory
                ? _getTraitString(params.filters.acc, "acimg", params.pos.accX, params.pos.accY)
                : "";

        uint32 packedHat = synthiaTraits.packXY(uint16(params.pos.hatX), uint16(params.pos.hatY));
        bool accessoryOverHat = params.pos.hatY == 0 || params.pos.hatY == 5 || packedHat == 262147;

        string memory hat = params.traitInfo.hasCustomHat
            ? _getCustomTraitSvgString(params.tokenId, 3)
            : params.traitInfo.hasHat ? _getTraitString(params.filters.hat, "htimg", params.pos.hatX, params.pos.hatY) : "";
        return string.concat(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">',
            _getDefs(
                params.colors,
                params.traitInfo.hasHat,
                params.pos.hatX,
                params.pos.hatY,
                params.pos.clothesX,
                params.pos.clothesY,
                params.pos.hairX,
                params.pos.hairY
            ),
            '<g clip-path="url(#c)">',
            '<rect width="400" height="400" fill="',
            params.colors.bg,
            '" />',
            _getBodyString(params.pos.bodyX, params.filters, params.traitInfo),
            params.overrides.clothes
                ? ""
                : !params.isHood
                    ? params.traitInfo.hasCustomClothes ? _getCustomTraitSvgString(params.tokenId, 0) : params.clothes
                    : "",
            params.overrides.hair
                ? ""
                : params.traitInfo.hasCustomHair
                    ? _getCustomTraitSvgString(params.tokenId, 1)
                    : params.traitInfo.hasHair
                        ? string.concat(
                            '<g clip-path="url(#hcp)">',
                            _getTraitString(params.filters.hair, "himg", params.pos.hairX, params.pos.hairY),
                            "</g>"
                        )
                        : "",
            accessoryOverHat ? params.overrides.hat ? "" : hat : params.overrides.accessory ? "" : accessory,
            accessoryOverHat ? params.overrides.accessory ? "" : accessory : params.overrides.hat ? "" : hat,
            params.overrides.clothes
                ? ""
                : params.isHood
                    ? params.traitInfo.hasCustomClothes ? _getCustomTraitSvgString(params.tokenId, 0) : params.clothes
                    : "",
            "</g></svg>"
        );
    }

    struct CustomTrait {
        address contractAddress;
        uint256 tokenId;
    }

    mapping(uint256 => mapping(uint256 => CustomTrait)) public tokenIdToIdxToCustomTrait;

    function clearCustomTrait(uint256 tokenId, uint256 idx) public onlyTraitAdmin {
        delete tokenIdToIdxToCustomTrait[tokenId][idx];
    }

    function _getCustomTraitSvgString(uint256 tokenId, uint256 idx) internal view returns (string memory) {
        return string.concat('<image href="', _getCustomTraitImage(tokenId, idx), '" width="400" height="400"></image>');
    }

    function hasCustomTrait(uint256 tokenId, uint256 idx) public view returns (bool) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];
        if (trait.contractAddress == address(0)) {
            return false;
        }

        try IERC721OwnerOf(trait.contractAddress).ownerOf(trait.tokenId) returns (address owner) {
            if (synthia.ownerOf(tokenId) != owner) {
                return false;
            }
            return true;
        } catch {
            return false;
        }
    }

    function _getCustomTraitImage(uint256 tokenId, uint256 idx) internal view returns (string memory) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];

        try ISynthiaTraitsERC721(trait.contractAddress).getTraitImage(trait.tokenId) returns (string memory traitImage)
        {
            return traitImage;
        } catch {
            return "";
        }
    }

    function setCustomTrait(uint256 tokenId, uint256 idx, address traitContractAddress, uint256 traitTokenId)
        public
        onlyTraitAdmin
    {
        tokenIdToIdxToCustomTrait[tokenId][idx] =
            CustomTrait({contractAddress: traitContractAddress, tokenId: traitTokenId});
    }

    function setCustomTraitWithOverrides(
        uint256 tokenId,
        uint256 idx,
        address traitContractAddress,
        uint256 traitTokenId,
        uint256 overrides
    ) public onlyTraitAdmin {
        tokenIdOverrides[tokenId] = overrides;
        setCustomTrait(tokenId, idx, traitContractAddress, traitTokenId);
    }

    function flipBit(uint256 num, uint8 position) public pure returns (uint256) {
        require(position < 256, "Bit position must be less than 256");
        return num ^ (1 << position);
    }

    // Function to check the boolean value at a specific position in a uint256
    function checkBit(uint256 num, uint8 position) public pure returns (bool) {
        require(position < 256, "Bit position must be less than 256");
        return ((num >> position) & 1) == 1;
    }

    function _getBodyString(uint256 bodyX, FilterId memory filters, TraitInfo memory traitInfo)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            "<use",
            bodyX == 3 ? string.concat(' filter="url(#', filters.shaman, ')"') : "",
            ' href="#bimg',
            '" x="-',
            Strings.toString(bodyX * 400),
            '" y="0" width="400" height="400" />',
            traitInfo.canBeHybrid && traitInfo.factionIdx == 2 && bodyX != 3
                ? string.concat(
                    "<use",
                    string.concat(' filter="url(#', filters.shaman, ')"'),
                    ' href="#bimg',
                    '" x="-',
                    Strings.toString(4 * 400),
                    '" y="0" width="400" height="400" />'
                )
                : ""
        );
    }

    function _getTraitString(string memory filterId, string memory href, uint256 x, uint256 y)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<use filter="url(#',
            filterId,
            ')" href="#',
            href,
            '" x="-',
            Strings.toString(x * 400),
            '" y="-',
            Strings.toString(y * 400),
            '" width="400" height="400" />'
        );
    }

    // WARNING: Additional state variables should go below everything.
    mapping(uint256 => uint256) public tokenIdOverrides;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity >=0.6.2 <0.9.0;

interface ISynthiaTraitsERC721 {
    /// @dev Function MUST return a valid index for the trait it represents
    function getTraitIndex(uint256 tokenId) external view returns (uint256);

    /// @dev Gets the custom name of the given trait item. This should not be confused with the trait name from ISynthiaErc721.
    /// The trait name from ISynthiaErc721 would be "head" where here it would be the name of the item place on the "head" such as "red hat".
    function getTraitName(uint256 tokenId) external view returns (string memory);

    /// @dev Function MUST return the base64 url for a give token ID which represents a trait
    function getTraitImage(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solmate/utils/SSTORE2.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract SynthiaData is Owned {
    constructor() Owned(msg.sender) {}

    event Record(string indexed name, address pointer);
    event Register(string indexed name);

    error AlreadyRegistered();
    error DoesntExist();
    error MaxSizeReached();
    error Unauthorized();

    struct DataChunks {
        address owner;
        address[] chunks;
        uint256 maxChunks;
    }

    mapping(bytes32 => DataChunks) public data;

    ////////////////////////////////
    // Unverfied Data Functions
    ////////////////////////////////

    /// Registers unverified data using a string name as key
    function registerData(string calldata name, uint256 maxChunks) public {
        bytes32 nameHash = getNameHash(name);
        if (data[nameHash].owner != address(0)) {
            revert AlreadyRegistered();
        }
        data[nameHash].owner = msg.sender;
        data[nameHash].maxChunks = maxChunks;
        emit Register(name);
    }

    function record(string memory name, string calldata _data) public returns (address) {
        bytes32 id = getNameHash(name);
        if (data[id].owner == address(0)) {
            revert DoesntExist();
        }
        if (data[id].chunks.length + 1 > data[id].maxChunks) {
            revert MaxSizeReached();
        }
        if (msg.sender != data[id].owner) {
            revert Unauthorized();
        }
        address pointer = SSTORE2.write(bytes(_data));
        data[id].chunks.push(pointer);
        emit Record(name, pointer);
        return pointer;
    }

    function getNumberOfChunks(string calldata name) public view returns (uint256) {
        return data[getNameHash(name)].chunks.length;
    }

    function getChunkAtIndex(string calldata name, uint256 idx) public view returns (string memory) {
        return getChunk(data[getNameHash(name)].chunks[idx]);
    }

    function getNameHash(string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function getData(string calldata name) public view returns (string memory output) {
        for (uint256 i = 0; i < getNumberOfChunks(name); i++) {
            output = string(abi.encodePacked(output, getChunkAtIndex(name, i)));
        }
    }

    function getChunk(address pointer) public view returns (string memory) {
        return string(SSTORE2.read(pointer));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

pragma solidity ^0.8.0;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {SynthiaRenderer} from "./SynthiaRenderer.sol";
import {ISynthiaERC721} from "./ISynthiaERC721.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

interface IErc721BalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC721OwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Synthia is ERC721A, Ownable {
    SynthiaRenderer public renderer;
    uint256 public mintPrice = 0.029 ether;
    uint256 public heroPrice = 0.025 ether;
    uint public maxSupply = 10000;
    bytes32 public guaranteedMintMerkleRoot;
    uint256 public randomness;
    address heroes;
    mapping(address => bool) public wlCollections;
    mapping(address => uint) public gmMints;

    struct Dates {
        uint256 startWl;
        uint256 startGuaranteed;
        uint256 startPub;
    }

    Dates dates;

    error ErrorMessage(string);

    bytes32 public seedHash;
    uint256 public seed;
    address public wallet;
    bool public useCdn;
    string public cdnBase;

    constructor(
        uint256 startGuaranteed,
        uint256 startWl,
        uint256 startPub,
        address _wallet,
        bytes32 _seedHash,
        bytes32 _root,
        address _heroes
    ) ERC721A("Synthia", "SYN") {
        _mintERC2309(msg.sender, 555);
        heroes = _heroes;
        dates.startWl = startWl;
        dates.startGuaranteed = startGuaranteed;
        dates.startPub = startPub;
        seedHash = _seedHash;
        wallet = _wallet;
        guaranteedMintMerkleRoot = _root;
    }

    function addWlCollections(address[] memory collections) public onlyOwner {
        for (uint i = 0; i < collections.length; i++) {
            wlCollections[collections[i]] = true;
        }
    }

    function setRoot(bytes32 _root) public onlyOwner {
        guaranteedMintMerkleRoot = _root;
    }

    function updateUseCdn(bool val) public onlyOwner {
        useCdn = val;
    }

    function updateCdnBase(string memory base) public onlyOwner {
        cdnBase = base;
    }

    function updateWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function updateDates(
        uint256 _startWl,
        uint256 _startGuaranteed,
        uint256 _startPub
    ) public onlyOwner {
        dates.startWl = _startWl;
        dates.startGuaranteed = _startGuaranteed;
        dates.startPub = _startPub;
    }

    function setRenderer(address _renderer) public onlyOwner {
        if (address(renderer) != address(0)) {
            revert ErrorMessage("Renderer set");
        }
        renderer = SynthiaRenderer(_renderer);
    }

    modifier wlStarted() {
        if (block.timestamp < dates.startWl) {
            revert ErrorMessage("WL not started");
        }
        _;
    }

    modifier guaranteedStarted() {
        if (block.timestamp < dates.startGuaranteed) {
            revert ErrorMessage("Guaranteed mint not started");
        }
        _;
    }

    modifier publicStarted() {
        if (block.timestamp < dates.startPub) {
            revert ErrorMessage("Public mint not started");
        }
        _;
    }

    modifier maxSupplyCheck(uint amount) {
        uint totalMinted = _totalMinted();
        if (amount > maxMintPerTx) {
            revert ErrorMessage("Amount gt max mint per tx");
        }
        if (totalMinted == maxSupply) {
            revert ErrorMessage("Max supply reached");
        }
        if (totalMinted + amount > maxSupply) {
            revert ErrorMessage("Invalid amount");
        }
        _;
    }

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function revealSeed(uint256 _seed, bytes32 _nonce) public onlyOwner {
        if (seed != 0) {
            revert ErrorMessage("Seed aleady revealed");
        }

        bytes32 hashCheck = keccak256(abi.encodePacked(_seed, _nonce));
        require(hashCheck == seedHash, "Invalid seed or nonce");

        seed = _seed;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    uint public maxMintPerTx = 20;

    function guaranteedMint(
        uint256 amount,
        bytes32[] calldata proof
    ) public payable guaranteedStarted {
        if (gmMints[msg.sender] + amount > maxMintPerTx) {
            revert ErrorMessage("GM Mint only allowed 20 per wallet");
        }
        uint price = mintPrice;
        try IErc721BalanceOf(heroes).balanceOf(msg.sender) returns (
            uint balance
        ) {
            if (balance > 1) {
                price = heroPrice;
            }
        } catch {
            // If an error occurs during the external call, price stays as mintPrice
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProofLib.verify(proof, guaranteedMintMerkleRoot, leaf)) {
            revert ErrorMessage("Invalid proof");
        }
        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        gmMints[msg.sender] += amount;
        _internalMint(amount);
    }

    function mintWithAddress(
        uint256 amount,
        address wlAddress
    ) public payable wlStarted {
        bool isWl = wlCollections[wlAddress];
        bool isHero = wlAddress == heroes;
        if (!isWl && !isHero) {
            revert ErrorMessage("Invalid WL address");
        }
        if (IErc721BalanceOf(wlAddress).balanceOf(msg.sender) < 1) {
            revert ErrorMessage("Must own NFT from WL collection");
        }
        uint256 price = isHero ? heroPrice : mintPrice;

        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        _internalMint(amount);
    }

    function mint(uint amount) public payable publicStarted {
        bool isHero = IErc721BalanceOf(heroes).balanceOf(msg.sender) > 0;
        uint256 price = isHero ? heroPrice : mintPrice;
        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        _internalMint(amount);
    }

    function _internalMint(uint256 amount) internal maxSupplyCheck(amount) {
        (bool sent, ) = wallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        _mint(msg.sender, amount);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        return uint256(keccak256(abi.encode(randomness, tokenId)));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ErrorMessage("Token ID does not exist");
        }
        if (seed == 0) {
            // Return pre-revealed data
            return renderer.getPrerevealMetadataUri();
        }
        if (useCdn) {
            return string.concat(cdnBase, Strings.toString(tokenId));
        } else {
            return renderer.getMetadataDataUri(getSeed(tokenId), tokenId);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}

pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract SynthiaTraits is Ownable {
    string[] bgColors = [
        "#FF2079",
        "#28fcb3",
        "#1C1C1C",
        "#7122FA",
        "#FDBC3B",
        "#1ba6fe"
    ];

    function getClothesName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;
        if (position == 0) {
            name = "Rustic Cotton Shirt";
        } else if (position == 65536) {
            name = "Rebel Collar Shirt";
        } else if (position == 131072) {
            name = "Earthbound Hooded Shirt";
        } else if (position == 196608) {
            name = "Naturalist Layered Tunic";
        } else if (position == 262144) {
            name = "Traditional Linen Shirt";
        } else if (position == 1) {
            name = "Clandestine Button-Down";
        } else if (position == 65537) {
            name = "Stealth-Tech Long Sleeve";
        } else if (position == 131073) {
            name = "Encryptor Shirt";
        } else if (position == 196609) {
            name = "Cipher Shirt";
        } else if (position == 262145) {
            name = "Holographic Hoodie";
        } else if (position == 2) {
            name = "Transcendent Shoulderless Top";
        } else if (position == 65538) {
            name = "Mystic Cutaway Shirt";
        } else if (position == 131074) {
            name = "Spiritual Circuit Cowl";
        } else if (position == 196610) {
            name = "Enchanted Tech Hoodie";
        } else if (position == 262146) {
            name = "Etheric Energy Shirt";
        } else if (position == 3) {
            name = "Cybernetic Infiltrator Jacket";
        } else if (position == 65539) {
            name = "Stealth Matrix Jacket";
        } else if (position == 131075) {
            name = "Hologram Hacker Jacket";
        } else if (position == 196611) {
            name = "Firewall Breaker Jacket";
        } else if (position == 262147) {
            name = "Cryptic Code Hoodie";
        } else if (position == 4) {
            name = "Harmonic Interface Bodysuit";
        } else if (position == 65540) {
            name = "Dual Existence Exoskeleton";
        } else if (position == 131076) {
            name = "Fusion Suit";
        } else if (position == 196612) {
            name = "Adaptive Synthesis Jumpsuit";
        } else if (position == 262148) {
            name = "Biomechanical Balance Armor";
        } else if (position == 5) {
            name = "Autonomous Muscle Shirt";
        } else if (position == 65541) {
            name = "Off The Grid Shirt";
        } else if (position == 131077) {
            name = "Autonomous Jacket";
        } else if (position == 196613) {
            name = "Independent Shirt";
        } else if (position == 262149) {
            name = "Privacy Shoulder Guard";
        }

        return name;
    }

    function getHairName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;
        if (position == 0) {
            name = "Wild Tangle";
        } else if (position == 65536) {
            name = "Windswept Waves";
        } else if (position == 131072) {
            name = "Nature Inspired Volume";
        } else if (position == 196608) {
            name = "Rustic Updo";
        } else if (position == 262144) {
            name = "Earthy Braids";
        } else if (position == 1) {
            name = "Sleek Side Sweep";
        } else if (position == 65537) {
            name = "Holographic Tie Back";
        } else if (position == 131073) {
            name = "Futuristic Buzz";
        } else if (position == 196609) {
            name = "Covert Pony";
        } else if (position == 262145) {
            name = "Digital Duality Crew";
        } else if (position == 2) {
            name = "Spirit-Woven Locks";
        } else if (position == 65538) {
            name = "Aetheric Locks";
        } else if (position == 131074) {
            name = "Chakra-Balanced Curls";
        } else if (position == 196610) {
            name = "Mystic Baldness";
        } else if (position == 262146) {
            name = "Enchanted Long Hair";
        } else if (position == 3) {
            name = "Datastream";
        } else if (position == 65539) {
            name = "Glitchy Buzzcut";
        } else if (position == 131075) {
            name = "Cyberpunk Slick";
        } else if (position == 196611) {
            name = "Matrix Slick";
        } else if (position == 262147) {
            name = "Datastream Quiff";
        } else if (position == 4) {
            name = "Biomech Fringe";
        } else if (position == 65540) {
            name = "Hybrid Side Sweep";
        } else if (position == 131076) {
            name = "Synthesized Spikes";
        } else if (position == 196612) {
            name = "Organic Circuit";
        } else if (position == 262148) {
            name = "Two-Worlds Tousle";
        } else if (position == 5) {
            name = "Free Spirit Patch";
        } else if (position == 65541) {
            name = "Liberated Side Shave";
        } else if (position == 131077) {
            name = "Unbound Layered Cut";
        } else if (position == 196613) {
            name = "Outlier Long-Straight";
        } else if (position == 262149) {
            name = "Rebel Pomp";
        }

        return name;
    }

    function getHatName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;

        if (position == 0) {
            name = "Timeless Bowler Cap";
        } else if (position == 65536) {
            name = "Heritage Bowler Hat";
        } else if (position == 131072) {
            name = "Nature's Embrace Headband";
        } else if (position == 196608) {
            name = "Organic Slouch Beanie";
        } else if (position == 262144) {
            name = "Earthen Earflap Hat";
        } else if (position == 1) {
            name = "Enigma Infiltrator Helmet";
        } else if (position == 65537) {
            name = "Shadow Broker Visor";
        } else if (position == 131073) {
            name = "Veiled Intellect Headgear";
        } else if (position == 196609) {
            name = "Cryptic Interface Helm";
        } else if (position == 262145) {
            name = "Secret Network Visor";
        } else if (position == 2) {
            name = "Astral Resonance Headpiece";
        } else if (position == 65538) {
            name = "Transcendent Energy Veil";
        } else if (position == 131074) {
            name = "Spirit-Tech Headgear";
        } else if (position == 196610) {
            name = "Mystical Sound Mask";
        } else if (position == 262146) {
            name = "Etheric Amplifier Crown";
        } else if (position == 3) {
            name = "Anonymous Infiltrator Mask";
        } else if (position == 65539) {
            name = "Firewall Breacher Helmet";
        } else if (position == 131075) {
            name = "Holographic Intruder Helm";
        } else if (position == 196611) {
            name = "Decryption Master Headpiece";
        } else if (position == 262147) {
            name = "Cyber Stealth Bandana";
        } else if (position == 4) {
            name = "Cyber-Organic Circlet";
        } else if (position == 65540) {
            name = "Symbiotic Synthesis Helmet";
        } else if (position == 131076) {
            name = "Harmony Seeker Mask";
        } else if (position == 196612) {
            name = "Dual-Worlds Visor";
        } else if (position == 262148) {
            name = "Integrated Identity Module";
        } else if (position == 5) {
            name = "Off-Grid Guardian Helm";
        } else if (position == 65541) {
            name = "Untraceable Survivor Helmet";
        } else if (position == 131077) {
            name = "Autonomous Defender Headgear";
        } else if (position == 196613) {
            name = "Rogue Resistor Helm";
        } else if (position == 262149) {
            name = "Hidden Haven Headpiece";
        }

        return name;
    }

    function getAccesoryName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;

        if (position == 0) {
            name = "Ancestral Insight Eyepiece";
        } else if (position == 65536) {
            name = "Primitive Vision Goggles";
        } else if (position == 131072) {
            name = "Luminous Earthbound Visor";
        } else if (position == 196608) {
            name = "Organic Barrier Face Shield";
        } else if (position == 262144) {
            name = "Nature's Whisper Mouthguard";
        } else if (position == 1) {
            name = "Neon Infiltrator Glasses";
        } else if (position == 65537) {
            name = "Covert Protector Mask";
        } else if (position == 131073) {
            name = "High-Tech Recon Goggles";
        } else if (position == 196609) {
            name = "Cipher Lens Eyewear";
        } else if (position == 262145) {
            name = "Datastream Vision Glasses";
        } else if (position == 2) {
            name = "Sacred Rune Amulet";
        } else if (position == 65538) {
            name = "Gem-Infused Divination Eye";
        } else if (position == 131074) {
            name = "Mystical Power Headband";
        } else if (position == 196610) {
            name = "Spirit Earring";
        } else if (position == 262146) {
            name = "Enchanted Vision Eyewear";
        } else if (position == 3) {
            name = "Encryption Mask";
        } else if (position == 65539) {
            name = "Partial Anonymity Face Guard";
        } else if (position == 131075) {
            name = "Digital Cloak Uplink Device";
        } else if (position == 196611) {
            name = "Full-Spectrum Security Mask";
        } else if (position == 262147) {
            name = "Hacked Identity Barrier";
        } else if (position == 4) {
            name = "Biomech Vision Enhancer";
        } else if (position == 65540) {
            name = "Synaptic Interface Goggles";
        } else if (position == 131076) {
            name = "Cyber-Organic Optics";
        } else if (position == 196612) {
            name = "Integrated Identity Faceplate";
        } else if (position == 262148) {
            name = "Human-Tech Fusion Eyewear";
        } else if (position == 5) {
            name = "Unbound Vision Goggles";
        } else if (position == 65541) {
            name = "Illuminated Isolation Mask";
        } else if (position == 131077) {
            name = "Rogue Optics Eyepiece";
        } else if (position == 196613) {
            name = "Autonomous Sight Enhancer";
        } else if (position == 262149) {
            name = "Independent Perception Goggles";
        }

        return name;
    }

    string description;

    function packXY(uint16 x, uint16 y) public pure returns (uint32) {
        return (uint32(x) << 16) | uint32(y);
    }

    // Extract x and y values from a uint32
    function unpackXY(uint32 packed) public pure returns (uint16 x, uint16 y) {
        x = uint16(packed >> 16);
        y = uint16(packed);
    }

    function getDescription() public view returns (string memory) {
        return
            bytes(description).length == 0
                ? "Synthia is a unique, AI-powered storytelling and gaming NFT project featuring customizable virtual avatars as ERC721 NFTs on the Ethereum blockchain. Set in a post-apocalyptic world, users can explore various factions, interact directly with Synthia and the factions through an immersive terminal experience, and participate in games. The on-chain, CC0 licensed art fuels a new creator economy, offering endless possibilities for the Synthia universe."
                : description;
    }

    function updateDescription(string memory _desc) public onlyOwner {
        description = _desc;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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

pragma solidity >=0.6.2 <0.9.0;

interface ISynthiaERC721 {
  /// @dev This function returns the total number of customizable traits
  function getTotalTraits() external view returns (uint256);

  /// @dev You can get the name of a trait by it's index. Indices are zero based
  /// and the max length can be retrieved by the getTotalTraits function. The lower the trait index
  /// the lower the trait layer when the image is rendered. Trait 0 will be on the bottom, trait 1 will be placed
  /// on top of trait 0 and so on.
  function getTraitNameByIndex(
    uint256 index
  ) external view returns (string memory);

  /// @dev Convenience method to determine if a specified trait is custom
  function hasCustomTrait(uint tokenId, uint idx) external view returns (bool);

  /// @dev Returns that contract address which contains the token ID for a given trait set for a given token ID.
  /// If no custom trait has been set then this function MUST return the zero address
  function getTraitContractAddress(
    uint tokenId,
    uint index
  ) external view returns (address);

  /// @dev Returns the token ID which represents the custom trait set on a given soul bound token.
  /// If no custom trait is set this function MUST throw. You can
  /// Check if a custom trait is set by verifying that the getTraitPointer return value is not the 0 address
  /// Token ownership MUST be checked here. The owner of the NFT and trait NFT MUST be the same.
  function getTraitTokenId(
    uint tokenId,
    uint index
  ) external view returns (uint);

  /// @dev Function MUST be called by owner of NFT. If a non-owner tries to call this function it MUST throw.
  /// Clears any associated external trait for the given token ID and index.
  function clearTrait(uint tokenId, uint index) external;

  /// @dev Function MUST be called by owner of NFT. If a non-owner tries to call this function it MUST throw.
  /// traitTokenId MUST be owned by owner of tokenId, if not function MUST throw. As a safeguard, index argument MUST match
  /// what is returned by getTraitIndex function from the pointer contract.
  function setTrait(
    uint tokenId,
    address traitContractAddress,
    uint traitTokenId,
    uint index
  ) external;

  /// @dev This function MUST return the base 64 URL of the fully layered image.
  function getImage(uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
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