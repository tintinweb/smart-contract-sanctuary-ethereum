// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IlluvitarsMetadataBuilderSpec.sol";
import "./interfaces/IlluvitarsSpec.sol";
import "./interfaces/DictionarySpec.sol";
import "./datatypes/PortraitDataTypes.sol";
import "./datatypes/AccessoryDataTypes.sol";
import "./datatypes/D1skDataTypes.sol";
import "base64-sol/base64.sol";

/**
 * @title Illuvitar Metadata Builder
 *
 * @dev Formats Illuvitars' metadata to conform with L1 markets standards (OpenSea, etc.)
 *
 * @dev Queries the PortraitDictionary and AccessoryDictionary to translate enum/uint8 metadata
 *  to the official property name (string)
 *
 * @author Yuri Fernandes
 */
contract IlluvitarsMetadataBuilderImpl is IlluvitarsMetadataBuilder, UUPSUpgradeable, OwnableUpgradeable {
    /// @dev Portrait Dictionary address
    address public portraitDictionary;

    /// @dev Accessory Dictionary address
    address public accessoryDictionary;

    /// @dev UUPSUpgradeable storage gap
    uint256[48] private __gap;

    /**
     * @dev Initialize Base Illuvitar.
     *
     * @param _portraitDictionary address of the PortraitDictionary
     * @param _accessoryDictionary address of the AccessoryDictionary
     */
    function initialize(address _portraitDictionary, address _accessoryDictionary) external initializer {
        require(_portraitDictionary != address(0), "Invalid Portrait Dictionary");
        require(_accessoryDictionary != address(0), "Invalid Accessory Dictionary");
        __Ownable_init();

        portraitDictionary = _portraitDictionary;
        accessoryDictionary = _accessoryDictionary;
    }

    function setPortraitDictionary(address _portraitDictionary) external onlyOwner {
        portraitDictionary = _portraitDictionary;
    }

    function setAccessoryDictionary(address _accessoryDictionary) external onlyOwner {
        accessoryDictionary = _accessoryDictionary;
    }

    function buildD1skMetadata(uint256 _tokenId) external view returns (string memory) {
        // assuming the function was called by the PortraitLayer contract itself,
        // fetch the token metadata from it
        bytes memory d1skMetadata;
        {
            string[9] memory d1skMetadataStrings = _getD1skMetadata(_tokenId, D1sk(msg.sender).metadata(_tokenId));
            for (uint8 i = 0; i < d1skMetadataStrings.length; i++) {
                d1skMetadata = abi.encodePacked(d1skMetadata, d1skMetadataStrings[i]);
            }
        }

        return string(abi.encodePacked("data:application/json;base64, ", Base64.encode(d1skMetadata)));
    }

    function buildPortraitMetadata(uint256 _tokenId) external view returns (string memory) {
        // assuming the function was called by the PortraitLayer contract itself,
        // fetch the token metadata from it
        bytes memory portraitMetadata;
        {
            string[9] memory portraitMetadataStrings = _getPortraitMetadata(
                _tokenId,
                PortraitLayer(msg.sender).metadata(_tokenId),
                PortraitDictionary(portraitDictionary)
            );
            for (uint8 i = 0; i < portraitMetadataStrings.length; i++) {
                portraitMetadata = abi.encodePacked(portraitMetadata, portraitMetadataStrings[i]);
            }
        }

        return string(abi.encodePacked("data:application/json;base64, ", Base64.encode(portraitMetadata)));
    }

    function buildAccessoryMetadata(uint256 _tokenId) external view returns (string memory) {
        // assuming the function was called by the AccessoryLayer contract itself,
        // fetch the token metadata from it
        bytes memory accessoryMetadata;
        {
            string[9] memory accessoryMetadataStrings = _getAccessoryMetadata(
                _tokenId,
                AccessoryLayer(msg.sender).metadata(_tokenId),
                AccessoryDictionary(accessoryDictionary)
            );
            for (uint8 i = 0; i < accessoryMetadataStrings.length; i++) {
                accessoryMetadata = abi.encodePacked(accessoryMetadata, accessoryMetadataStrings[i]);
            }
        }

        return string(abi.encodePacked("data:application/json;base64, ", Base64.encode(accessoryMetadata)));
    }

    function _getD1skMetadata(uint256 _tokenId, D1skMetadata memory _metadata)
        internal
        view
        returns (string[9] memory)
    {
        return [
            '{"name":"',
            _d1skName(_metadata),
            '", "description":"',
            _d1skDescription(_metadata),
            '", "attributes": "',
            _d1skAttributes(_metadata),
            '", "image": "',
            D1sk(msg.sender).tokenImageURI(_tokenId),
            '"}'
        ];
    }

    function _d1skName(D1skMetadata memory _metadata) internal pure returns (string memory) {
        if (_metadata.packType == PackType.Basic) return string(abi.encodePacked("Basic D1sk"));
        return string(abi.encodePacked("Ultra D1sk"));
    }

    function _d1skDescription(D1skMetadata memory _metadata) internal pure returns (string memory) {
        _metadata;
        return "";
    }

    function _d1skAttributes(D1skMetadata memory _metadata) internal pure returns (string memory) {
        bytes memory attributes = "[";
        attributes = abi.encodePacked(attributes, _formatAttribute("Set", string(_itoa8(_metadata.set))), ",");
        attributes = abi.encodePacked(attributes, _formatAttribute("Batch", string(_itoa8(_metadata.batch))), ",");
        attributes = abi.encodePacked(
            attributes,
            _formatAttribute("Pack Type", string(_translatePackType(_metadata.packType)))
        );

        return string(abi.encodePacked(attributes, "]"));
    }

    function _translatePackType(PackType _packType) internal pure returns (string memory) {
        if (_packType == PackType.Basic) return "Basic";
        return "Ultra";
    }

    function _getAccessoryMetadata(
        uint256 _tokenId,
        AccessoryMetadata memory _metadata,
        AccessoryDictionary _accessoryDictionary
    ) internal view returns (string[9] memory) {
        return [
            '{"name":"',
            _accessoryDictionary.name(uint8(_metadata.line), _metadata.stage),
            '", "description":"',
            _accessoryDictionary.description(uint8(_metadata.line), _metadata.stage),
            '", "attributes": "',
            _getAccessoryAttributes(_metadata, _accessoryDictionary),
            '", "image": "',
            AccessoryLayer(msg.sender).tokenImageURI(_tokenId),
            '"}'
        ];
    }

    function _getAccessoryAttributes(AccessoryMetadata memory _metadata, AccessoryDictionary _accessoryDictionary)
        internal
        view
        returns (string memory)
    {
        bytes memory accessoryAttributes = "[";
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Set", string(_itoa8(_metadata.set))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Batch", string(_itoa8(_metadata.batch))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Tier", string(_itoa8(_metadata.tier))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Line", _accessoryDictionary.line(uint8(_metadata.line))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Stage", string(_itoa8(_metadata.stage))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Type", string(_getAccessoryTypeArray(_metadata, _accessoryDictionary))),
            ", "
        );
        accessoryAttributes = abi.encodePacked(
            accessoryAttributes,
            _formatAttribute("Variation", _accessoryDictionary.variation(uint8(_metadata.variation))),
            ", "
        );

        return string(abi.encodePacked(accessoryAttributes, "]"));
    }

    function _getAccessoryTypeArray(AccessoryMetadata memory _metadata, AccessoryDictionary _accessoryDictionary)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodePacked(_accessoryDictionary.line(uint8(_metadata.line)), " Stage ", _itoa8(_metadata.stage));
    }

    function _getPortraitMetadata(
        uint256 _tokenId,
        PortraitMetadata memory _metadata,
        PortraitDictionary _portraitDictionary
    ) internal view returns (string[9] memory) {
        bytes memory portraitType;
        {
            string[7] memory portraitTypeStrings = _getPortraitTypeArray(_metadata, _portraitDictionary);
            for (uint8 i = 0; i < portraitTypeStrings.length; i++) {
                portraitType = abi.encodePacked(portraitType, portraitTypeStrings[i]);
            }
        }

        return [
            '{"name":"',
            _portraitDictionary.commonName(string(portraitType)),
            '", "description":"',
            PortraitLayer(msg.sender).description(),
            '", "attributes": "',
            _getPortraitAttributes(_metadata, _portraitDictionary),
            '", "image": "',
            PortraitLayer(msg.sender).tokenImageURI(_tokenId),
            '"}'
        ];
    }

    function _getPortraitTypeArray(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (string[7] memory)
    {
        if (_metadata.line == PortraitLine.Lynx) {
            return [
                "Lynx ",
                "Stage ",
                string(_itoa8(_metadata.stage)),
                " ",
                _portraitDictionary.affinity(uint8(_metadata.affinity)),
                " ",
                _portraitDictionary.class(uint8(_metadata.class))
            ];
        }
        if (_metadata.line == PortraitLine.Doka) {
            return [
                _portraitDictionary.affinity(uint8(_metadata.affinity)),
                " ",
                "Doka ",
                "stage ",
                string(_itoa8(_metadata.stage)),
                "",
                ""
            ];
        }
        if (_metadata.line == PortraitLine.Grokko) {
            return [
                _portraitDictionary.affinity(uint8(_metadata.affinity)),
                " ",
                "Grokko ",
                "stage ",
                string(_itoa8(_metadata.stage)),
                "",
                ""
            ];
        }
        if (_metadata.line == PortraitLine.Fliish) {
            return [
                _portraitDictionary.affinity(uint8(_metadata.affinity)),
                " ",
                "Fliish ",
                "stage ",
                string(_itoa8(_metadata.stage)),
                "",
                ""
            ];
        }
        return [
            _portraitDictionary.line(uint8(_metadata.line)),
            " stage ",
            string(_itoa8(_metadata.stage)),
            "",
            "",
            "",
            ""
        ];
    }

    function _getBackgroundType(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _portraitDictionary.backgroundVariation(uint8(_metadata.background.variation)),
                _portraitDictionary.backgroundLine(uint8(_metadata.background.line)),
                _itoa8(_metadata.background.stage)
            );
    }

    function _getPortraitAttributes(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (string memory)
    {
        bytes memory portraitAttributes;
        portraitAttributes = abi.encodePacked("[", _getIlluvitarAttributes(_metadata, _portraitDictionary), ", ");
        {
            string[6] memory backgroundAttributeStrings = _getBackgroundAttributes(_metadata, _portraitDictionary);
            for (uint8 i = 0; i < backgroundAttributeStrings.length; i++) {
                portraitAttributes = abi.encodePacked(portraitAttributes, backgroundAttributeStrings[i], ", ");
            }
        }

        {
            string[5] memory accessoryIdsStrings = _getAccessoryIDs(_metadata);
            for (uint8 i = 0; i < accessoryIdsStrings.length; i++) {
                portraitAttributes = abi.encodePacked(portraitAttributes, accessoryIdsStrings[i], " ,");
            }
        }

        return string(abi.encodePacked(portraitAttributes, "]"));
    }

    function _getAccessoryIDs(PortraitMetadata memory _metadata) internal pure returns (string[5] memory) {
        string[5] memory accessoryIdArray;
        accessoryIdArray[0] = _formatAttribute("Skin ID", string(_itoa256(_metadata.slots.skinId)));
        accessoryIdArray[1] = _formatAttribute("BodyWear ID", string(_itoa256(_metadata.slots.bodyId)));
        accessoryIdArray[2] = _formatAttribute("EyeWear ID", string(_itoa256(_metadata.slots.eyeId)));
        accessoryIdArray[3] = _formatAttribute("HeadWear ID", string(_itoa256(_metadata.slots.headId)));
        accessoryIdArray[4] = _formatAttribute("Prop ID", string(_itoa256(_metadata.slots.propId)));

        return accessoryIdArray;
    }

    function _formatAttribute(string memory _attributeName, string memory _attributeValue)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('{ "trait_type": "', _attributeName, '", "value": "', _attributeValue, '"}'));
    }

    function _getIlluvitarAttributes(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (bytes memory)
    {
        bytes memory illuvitarAttributes;
        {
            string[7] memory illuvitarGeneralAttributesStrings = _getIlluvitarGeneralAttributes(
                _metadata,
                _portraitDictionary
            );
            for (uint8 i = 0; i < illuvitarGeneralAttributesStrings.length; i++) {
                illuvitarAttributes = abi.encodePacked(illuvitarAttributes, illuvitarGeneralAttributesStrings[i], ", ");
            }
        }

        {
            string[4] memory illuvitarSpecificAttributesString = _getIlluvitarSpecificAttributes(
                _metadata,
                _portraitDictionary
            );
            for (uint8 i = 0; i < illuvitarSpecificAttributesString.length; i++) {
                illuvitarAttributes = abi.encodePacked(illuvitarAttributes, illuvitarSpecificAttributesString[i], ", ");
            }
        }

        return illuvitarAttributes;
    }

    function _getIlluvitarGeneralAttributes(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (string[7] memory)
    {
        bytes memory portraitType;
        {
            string[7] memory portraitTypeStrings = _getPortraitTypeArray(_metadata, _portraitDictionary);
            for (uint8 i = 0; i < portraitTypeStrings.length; i++) {
                portraitType = abi.encodePacked(portraitType, portraitTypeStrings[i]);
            }
        }

        string[7] memory illuvitarGeneralAttributeArray;
        illuvitarGeneralAttributeArray[0] = _formatAttribute("Set", string(_itoa8(_metadata.set)));
        illuvitarGeneralAttributeArray[1] = _formatAttribute("Batch", string(_itoa8(_metadata.batch)));
        illuvitarGeneralAttributeArray[2] = _formatAttribute("Tier", string(_itoa8(_metadata.tier)));
        illuvitarGeneralAttributeArray[3] = _formatAttribute("Line", _portraitDictionary.line(uint8(_metadata.line)));
        illuvitarGeneralAttributeArray[4] = _formatAttribute("Stage", string(_itoa8(_metadata.stage)));
        illuvitarGeneralAttributeArray[5] = _formatAttribute("Type", string(portraitType));
        illuvitarGeneralAttributeArray[6] = _formatAttribute(
            "Variation",
            _portraitDictionary.variation(uint8(_metadata.variation))
        );

        return illuvitarGeneralAttributeArray;
    }

    function _getIlluvitarSpecificAttributes(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (string[4] memory)
    {
        string[4] memory illuvitarSpecificAttributesArray;
        illuvitarSpecificAttributesArray[0] = _formatAttribute(
            "Expression",
            _portraitDictionary.expression(uint8(_metadata.expression))
        );
        illuvitarSpecificAttributesArray[1] = _formatAttribute(
            "Finish",
            _portraitDictionary.finish(uint8(_metadata.finish))
        );
        illuvitarSpecificAttributesArray[2] = _formatAttribute(
            "Affinity",
            _portraitDictionary.affinity(uint8(_metadata.affinity))
        );
        illuvitarSpecificAttributesArray[3] = _formatAttribute(
            "Class",
            _portraitDictionary.class(uint8(_metadata.class))
        );

        return illuvitarSpecificAttributesArray;
    }

    function _getBackgroundAttributes(PortraitMetadata memory _metadata, PortraitDictionary _portraitDictionary)
        internal
        view
        returns (string[6] memory)
    {
        bytes memory backgroundType = _getBackgroundType(_metadata, _portraitDictionary);

        string[6] memory backgroundAttributesArray;
        backgroundAttributesArray[0] = _formatAttribute("Background Set", string(_itoa8(_metadata.background.set)));
        backgroundAttributesArray[1] = _formatAttribute("Background Tier", string(_itoa8(_metadata.background.tier)));
        backgroundAttributesArray[2] = _formatAttribute(
            "Background Line",
            _portraitDictionary.backgroundLine(uint8(_metadata.background.line))
        );
        backgroundAttributesArray[3] = _formatAttribute("Background Stage", string(_itoa8(_metadata.background.stage)));
        backgroundAttributesArray[4] = _formatAttribute("Background Type", string(backgroundType));
        backgroundAttributesArray[5] = _formatAttribute(
            "Background Variation",
            _portraitDictionary.backgroundVariation(uint8(_metadata.background.variation))
        );

        return backgroundAttributesArray;
    }

    function _itoa256(uint256 i) internal pure returns (bytes memory a) {
        while (i != 0) {
            a = abi.encodePacked((i % 10) + 0x30, a);
            i /= 10;
        }
    }

    function _itoa8(uint8 i) internal pure returns (bytes memory a) {
        while (i != 0) {
            a = abi.encodePacked((i % 10) + 0x30, a);
            i /= 10;
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IlluvitarsMetadataBuilder {
    function buildPortraitMetadata(uint256 _tokenId) external view returns (string memory);

    function buildAccessoryMetadata(uint256 _tokenId) external view returns (string memory);

    function buildD1skMetadata(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../datatypes/PortraitDataTypes.sol";
import "../datatypes/AccessoryDataTypes.sol";
import "../datatypes/D1skDataTypes.sol";

interface PortraitLayer {
    function tokenImageURI(uint256 _tokenId) external view returns (string memory);

    function description() external pure returns (string memory);

    function metadata(uint256 _tokenId) external view returns (PortraitMetadata memory);
}

interface AccessoryLayer {
    function tokenImageURI(uint256 _tokenId) external view returns (string memory);

    function description() external pure returns (string memory);

    function metadata(uint256 _tokenId) external view returns (AccessoryMetadata memory);
}

interface D1sk {
    function tokenImageURI(uint256 _tokenId) external view returns (string memory);

    function description() external pure returns (string memory);

    function metadata(uint256 _tokenId) external view returns (D1skMetadata memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface PortraitDictionary {
    function commonName(string calldata _type) external view returns (string memory);

    function line(uint8 _line) external view returns (string memory);

    function affinity(uint8 _affinity) external view returns (string memory);

    function class(uint8 _class) external view returns (string memory);

    function variation(uint8 _variation) external view returns (string memory);

    function expression(uint8 _expression) external view returns (string memory);

    function finish(uint8 _finish) external view returns (string memory);

    function backgroundLine(uint8 _backgroundLine) external view returns (string memory);

    function backgroundVariation(uint8 _backgroundVariation) external view returns (string memory);
}

interface AccessoryDictionary {
    function name(uint8 _line, uint8 _stage) external view returns (string memory);

    function description(uint8 _line, uint8 _stage) external view returns (string memory);

    function line(uint8 _line) external view returns (string memory);

    function variation(uint8 _variation) external view returns (string memory);

    function slotType(uint8 _slotType) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum PortraitLine {
    Axolotl,
    Pterodactyl,
    SeaScorpion,
    Thylacine,
    Turtle,
    AntEater,
    Beetle,
    Dodo,
    Pangolin,
    Shoebill,
    StarNosedMole,
    Taipan,
    Squid,
    Snail,
    Penguin,
    Lynx,
    Doka,
    Grokko,
    Fliish
}

enum PortraitVariation {
    Original
}

enum Expression {
    Normal,
    Uncommon,
    Rare
}

enum Finish {
    Colour,
    Holo
}

enum Affinity {
    Water,
    Tsunami,
    Inferno,
    Nature,
    Granite,
    Air,
    Magma,
    Bloom,
    Fire,
    Shock,
    Frost,
    Neutral,
    Earth
}

enum Class {
    None,
    Bulwark,
    Harbinder,
    Phantom,
    Fighter,
    Rogue,
    Empath,
    Psion,
    Vanguard
}

enum BackgroundLine {
    Dots,
    Flash,
    Hexagon,
    Rain,
    Spotlight,
    M0z4rt,
    Affinity,
    Arena,
    Token,
    Encounter
}

enum BackgroundVariation {
    Original,
    Orange,
    Purple,
    Red,
    Teal,
    White,
    Yellow,
    Blue,
    Green,
    Mangenta,
    Air,
    Earth,
    Fire,
    Nature,
    Water,
    Rainbow
}

struct BackgroundMetadata {
    // Background metadata
    uint8 set;
    uint8 tier;
    BackgroundLine line;
    uint8 stage;
    BackgroundVariation variation;
}

struct SlotMetadata {
    // Bonded accessory token ids
    uint256 skinId; // bonded skin id
    uint256 bodyId; // bonded body id
    uint256 eyeId; // bonded eye wear id
    uint256 headId; // bonded head wear id
    uint256 propId; // bonded props id
}

/// @dev Illuvitar Metadata struct
struct PortraitMetadata {
    uint8 set;
    uint8 batch;
    uint8 tier; // tier
    PortraitLine line;
    uint8 stage;
    PortraitVariation variation;
    Expression expression;
    Finish finish;
    Affinity affinity;
    Class class;
    BackgroundMetadata background;
    SlotMetadata slots;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum SlotType {
    Skin,
    BodyWear,
    EyeWear,
    HeadWear,
    Prop
}

enum AccessoryLine {
    ClassyPipe,
    ClassyCigar,
    M0z4rtAntenna,
    IlluviumBadge,
    ClownNose,
    EyeScar,
    WarPaint,
    GlowingTattoo,
    Bandaid,
    Piercing,
    Halo,
    SoldierHelmet,
    Bandana,
    Fedora,
    IlluviumBaseballCap,
    ButterflyTie,
    NeckChain,
    QuantumCollar,
    Amulet,
    DogCollar,
    Sunglasses,
    Monocle,
    MemeGlasses,
    PartySlides,
    ILVCoins
}

enum AccessoryVariation {
    Original
}

/// @dev Accessory Metadata struct
struct AccessoryMetadata {
    uint8 set;
    uint8 batch;
    uint8 tier; // tier
    AccessoryLine line;
    uint8 stage;
    AccessoryVariation variation;
    SlotType slotType; // Slot type
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum PackType {
    Basic,
    Ultra
}

struct D1skMetadata {
    uint8 set;
    uint8 batch;
    PackType packType;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}