// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {KODASettings} from "../KODASettings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Metadata, IERC2981} from "./interfaces/IERC721KODAEditions.sol";
import {IERC721KODACreator} from "./interfaces/IERC721KODACreator.sol";

import {ERC721KODAEditions} from "./ERC721KODAEditions.sol";

/**
 * @author KnownOrigin Labs - https://knownorigin.io/
 *
 * @dev Contract which extends the KO Edition base enabling creator specific functionality
 */
contract ERC721KODACreator is ERC721KODAEditions, IERC721KODACreator {
    /**
     * @notice KODA Settings
     * @dev Defines the global settings for the linked KODA platform
     */
    KODASettings public kodaSettings;

    /**
     * @notice Default Funds Handler
     * @dev Address of the fund handler that receives funds for all editions if an alternative has not been set in {_editionFundsHandler}
     */
    address public defaultFundsHandler;

    /**
     * @notice Additional address enabled as a minter
     * @dev returns true if the address has been enabled as an additional minter
     *
     * - requires addition logic in place in inherited minting contracts
     */
    mapping(address => bool) public additionalMinterEnabled;

    /**
     * @notice Additional address enabled as creators of editions
     * @dev returns true if the address has been enabled as an additional creator
     *
     */
    mapping(address => bool) public additionalCreatorEnabled;

    /// @dev mapping of edition ID => address of the fund handler for a specific edition
    mapping(uint256 => address) internal _editionFundsHandler;

    modifier onlyApprovedMinter() {
        _onlyApprovedMinter();
        _;
    }

    modifier onlyApprovedCreator() {
        _onlyApprovedCreator();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev initialize method that replaces constructor in upgradeable contract
     *
     * Requirements:
     *
     * - `_artistAndOwner` must not be the zero address
     * - `_name` and `_symbol` must not be empty strings
     * - `_defaultFundsHandler` must not be the zero address
     * - `_settings` must not be the zero address
     * - should call all upgradeable `__[ContractName]_init()` methods from inherited contracts
     *
     * @param _artistAndOwner Who will be assigned attribution as lead artist and initial owner of the contract.
     * @param _name the NFT name
     * @param _symbol the NFT symbol
     * @param _defaultFundsHandler the address of the default address for receiving funds for all editions
     * @param _settings address of the platform KODASettings contract
     * @param _secondaryRoyaltyPercentage the default percentage value used for calculating royalties for secondary sales
     */
    function initialize(
        address _artistAndOwner,
        string calldata _name,
        string calldata _symbol,
        address _defaultFundsHandler,
        KODASettings _settings,
        uint256 _secondaryRoyaltyPercentage,
        address _KOOperatorRegistry
    ) external initializer {
        if (_artistAndOwner == address(0)) revert ZeroAddress();
        if (address(_settings) == address(0)) revert ZeroAddress();
        if (_defaultFundsHandler == address(0)) revert ZeroAddress();

        if (_artistAndOwner == address(this)) revert InvalidOwner();
        if (bytes(_name).length == 0 || bytes(_symbol).length == 0)
            revert EmptyString();

        name = _name;
        symbol = _symbol;

        defaultFundsHandler = _defaultFundsHandler;
        kodaSettings = _settings;
        nextEditionId = MAX_EDITION_SIZE;
        originalDeployer = _artistAndOwner;

        __KODABase_init(_secondaryRoyaltyPercentage);
        __Module_init(_KOOperatorRegistry);

        _transferOwnership(_artistAndOwner);
    }

    /// @dev Allow a module to define custom init logic
    function __Module_init(address) internal virtual {}

    // ********** //
    // * PUBLIC * //
    // ********** //

    function contractURI() public view returns (string memory) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            string.concat(
                kodaSettings.baseKOApi(),
                "/network/",
                Strings.toString(id),
                "/contracts/",
                Strings.toHexString(address(this))
            );
    }

    // * Contract Metadata * //

    /**
     * @notice Royalty Info for a Token Sale
     * @dev returns the royalty details for the edition a token belongs to - falls back to defaults
     * @param _tokenId the id of the token being sold
     * @param _salePrice currency/token agnostic sale price
     * @return receiver address to send royalty consideration to
     * @return royaltyAmount value to be sent to the receiver
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        uint256 editionId = _tokenEditionId(_tokenId);

        receiver = editionFundsHandler(editionId);
        royaltyAmount =
            (_salePrice * editionRoyaltyPercentage(editionId)) /
            MODULO;
    }

    /**
     * @notice Check for Interface Support
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * @param interfaceId the ID of the interface to check
     * @return bool the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || // ERC165
            interfaceId == type(IERC721).interfaceId || // ERC721
            interfaceId == type(IERC721Metadata).interfaceId || // ERC721 Metadata
            interfaceId == type(IERC2981).interfaceId || // ERC2981
            interfaceId == type(IERC721KODACreator).interfaceId;
    }

    /**
     * @notice Version of the Contract used in combination with {description}
     * @dev Function value can be more easily updated in event of an upgrade
     * @return string semver version
     */
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    // * Editions * //

    /**
     * @notice Edition Funds Handler
     * @dev Returns the address that will receive sale proceeds for a given edition
     * @param _editionId the ID of an edition
     * @return address the funds handler address
     */
    function editionFundsHandler(
        uint256 _editionId
    ) public view override returns (address) {
        address fundsHandler = _editionFundsHandler[_editionId];

        if (fundsHandler != address(0)) {
            return fundsHandler;
        }

        return defaultFundsHandler;
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId
    ) public view override returns (uint256) {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return
            _getNextAvailablePrimarySaleToken(
                _editionId,
                _editionMaxTokenId(_editionId)
            );
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @param _startId the ID of the starting point to look for the next token to sell
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) public view override returns (uint256) {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return _getNextAvailablePrimarySaleToken(_editionId, _startId);
    }

    /**
     * @notice Mint An Open Edition Token
     * @dev allows the contract owner or additional minter to mint an open edition token
     * @param _editionId the ID of the edition to mint a token from
     * @param _recipient the address to transfer the token to
     */
    function mintOpenEditionToken(
        uint256 _editionId,
        address _recipient
    ) public override onlyApprovedMinter returns (uint256) {
        return _mintSingleOpenEditionTo(_editionId, _recipient);
    }

    /**
     * @notice Mint Multiple Open Edition Tokens to the Edition Owner
     * @dev allows the contract owner or additional minter to mint
     * @param _editionId the ID of the edition to mint a token from
     * @param _quantity the number of tokens to mint
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) public virtual override onlyApprovedMinter {
        if (_recipient != editionOwner(_editionId)) revert InvalidRecipient();
        _mintMultipleOpenEditionToOwner(_editionId, _quantity);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Create a new Edition - optionally mint tokens and set a custom creator address and edition metadata URI
     * @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
     * @param _editionSize the initial maximum supply of tokens in the edition
     * @param _mintQuantity the number of tokens to mint upfront - minting less than the edition size is considered an open edition
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional creator address to reflected in edition details
     * @param _uri the URI for fixed edition metadata
     * @return uint256 the new edition ID
     */
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256) {
        // mint to the minter or owner if address not specified
        address to = _recipient == address(0) ? additionalCreatorEnabled[msg.sender] ? msg.sender : owner() : _recipient;

        return _createEdition(_editionSize, _mintQuantity, to, _creator, _uri);
    }

    /**
     * @notice Create a new Edition as a collaboration with another entity, passing in a seperate funds handler for the edition - optionally mint tokens and set a custom creator address and edition metadata URI
     * @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address, setting metadata and a funds handler for this edition
     * @param _editionSize the initial maximum supply of tokens in the edition
     * @param _mintQuantity the number of tokens to mint upfront - minting less than the edition size is considered an open edition
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional creator address to reflected in edition details
     * @param _collabFundsHandler the address for receiving funds for this edition
     * @param _uri the URI for fixed edition metadata
     * @return editionId the new edition ID
     */
    function createEditionAsCollaboration(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        address _collabFundsHandler,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256 editionId) {
        // mint to the minter or owner if address not specified
        address to = _recipient == address(0) ? additionalCreatorEnabled[msg.sender] ? msg.sender : owner() : _recipient;

        editionId = _createEdition(
            _editionSize,
            _mintQuantity,
            to,
            _creator,
            _uri
        );

        _updateEditionFundsHandler(editionId, _collabFundsHandler);
    }

    /**
     * @notice Create Edition and Mint All Tokens to Owner
     * @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) public override onlyOwner returns (uint256) {
        return
            _createEdition(
                _editionSize,
                _editionSize,
                owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Create Edition for Lazy Minting
     * @dev Allows the contract owner to create an edition of specified size for lazy minting
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createOpenEdition(
        uint32 _editionSize,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256) {
        return
            _createEdition(
                _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
                0,
                additionalCreatorEnabled[msg.sender] ? msg.sender : owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Create Edition for Lazy Minting as a collaboration
     * @dev Allows the contract owner to create an edition of specified size for lazy minting as a collaboration with another entity, passing in a seperate funds handler for the edition
     * @param _editionSize the number of tokens in the edition
     * @param _collabFundsHandler the address for receiving funds for this edition
     * @param _uri the metadata URI for the edition
     * @return editionId the new edition ID
     */
    function createOpenEditionAsCollaboration(
        uint32 _editionSize,
        address _collabFundsHandler,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256 editionId) {
        editionId = _createEdition(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            0,
            additionalCreatorEnabled[msg.sender] ? msg.sender : owner(),
            address(0),
            _uri
        );

        _updateEditionFundsHandler(editionId, _collabFundsHandler);
    }

    /**
     * @notice Enable/disable minting using an additional address
     * @dev allows the contract owner to enable/disable additional minting addresses
     * @param _minter address of the additional minter
     * @param _enabled whether the address is able to mint
     */
    function updateAdditionalMinterEnabled(
        address _minter,
        bool _enabled
    ) external onlyOwner {
        additionalMinterEnabled[_minter] = _enabled;
        emit AdditionalMinterEnabled(_minter, _enabled);
    }

    /**
     * @notice Enable/disable edition creation using an additional address
     * @dev allows the contract owner to enable/disable additional creator addresses
     * @param _creator address of the additional creator
     * @param _enabled whether the address is able to be a creator
     */
    function updateAdditionalCreatorEnabled(
        address _creator,
        bool _enabled
    ) external onlyOwner {
        additionalCreatorEnabled[_creator] = _enabled;
        emit AdditionalCreatorEnabled(_creator, _enabled);
    }

    /**
     * @notice Update Edition Funds Handler
     * @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
     * @param _editionId the ID of the edition
     * @param _fundsHandler the address of the new funds handler for the edition
     */
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) public override onlyOwner {
        _updateEditionFundsHandler(_editionId, _fundsHandler);
    }

    /// @dev Internal logic for updating edition level funds handler overriding default
    function _updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) internal {
        if (_fundsHandler == address(0)) revert ZeroAddress();
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
        if (_editionFundsHandler[_editionId] != address(0)) revert AlreadySet();
        _editionFundsHandler[_editionId] = _fundsHandler;
        emit EditionFundsHandlerUpdated(_editionId, _fundsHandler);
    }

    /**
     * @notice Update Edition Size
     * @dev allows the contract owner to update the number of tokens that can be minted in an edition
     *
     * Requirements:
     *
     * - should not allow edition size to exceed {Konstants-MAX_EDITION_SIZE}
     * - should not allow edition size to be reduced to less than has already been minted
     *
     * @param _editionId the ID of the edition to change the size of
     * @param _editionSize the new size to set for the edition
     *
     * Emits an {EditionSizeUpdated} event.
     */
    function updateEditionSize(
        uint256 _editionId,
        uint32 _editionSize
    ) public override onlyOwner onlyOpenEdition(_editionId) {
        // can't set edition size beyond maximum
        if (_editionSize > MAX_EDITION_SIZE) revert EditionSizeTooLarge();

        unchecked {
            // can't reduce edition size to less than what has been minted already
            if (_editionSize < editionMintedCount(_editionId))
                revert EditionSizeTooSmall();
        }

        _editions[_editionId].editionSize = _editionSize;
        emit EditionSizeUpdated(_editionId, _editionSize);
    }

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(
        uint256 _editionId,
        string calldata _newURI
    ) external override onlyOwner {
        if (isOpenEdition(_editionId)) {
            if (_owners[_editionId] != address(0)) revert PrimarySaleMade();
        }

        if (
            _owners[_editionId + editionMintedCount(_editionId) - 1] !=
            address(0)
        ) revert PrimarySaleMade();

        _editions[_editionId].uri = _newURI;

        emit EditionURIUpdated(_editionId);
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Contract Ownership * //

    // @dev Handle transferring and renouncing ownership in one go where owner always has a minimum balance
    // @dev See balanceOf for how the return value is adjusted. We just do this to reduce minting GAS
    function _transferOwnership(address _newOwner) internal override {
        // This is for keeping the balance slot of owner 'dirty'
        address _currentOwner = owner();
        if (_currentOwner != address(0)) {
            _balances[_currentOwner] -= 1;
        }
        if (_newOwner != address(0)) {
            _balances[_newOwner] += 1;
        }

        super._transferOwnership(_newOwner);
    }

    // * Sale Helpers * //

    function _facilitateNextPrimarySale(
        uint256 _editionId,
        address _recipient
    ) internal virtual validateEdition(_editionId) returns (uint256 tokenId) {
        if (_editionSalesDisabled[_editionId]) revert EditionDisabled();

        // Process open edition sale
        if (isOpenEdition(_editionId)) {
            return _facilitateOpenEditionSale(_editionId, _recipient);
        }

        // process batch minted edition
        tokenId = getNextAvailablePrimarySaleToken(_editionId);

        // Re-enter this contract to make address(this) the sender for transferring which should be approved to transfer tokens
        ERC721KODACreator(address(this)).transferFrom(
            ownerOf(tokenId),
            _recipient,
            tokenId
        );
    }

    function _facilitateOpenEditionSale(
        uint256 _editionId,
        address _recipient
    ) internal virtual returns (uint256) {
        // Mint the token on demand
        uint256 tokenId = _mintSingleOpenEditionTo(_editionId, _recipient);

        // Return the token ID
        return tokenId;
    }

    function _getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) internal view virtual returns (uint256) {
        unchecked {
            // high to low
            for (_startId; _startId >= _editionId; --_startId) {
                // if no owner set - assume primary if not moved
                if (_owners[_startId] == address(0)) {
                    return _startId;
                }
            }
        }

        revert("Primary market exhausted");
    }

    // * Validators * //

    /// @dev validates that msg.sender is the contract owner or additional minter
    function _onlyApprovedMinter() internal virtual {
        if (msg.sender == owner()) return;
        if (additionalMinterEnabled[msg.sender]) return;
        revert NotAuthorised();
    }

    /// @dev validates that msg.sender is the contract owner or additional creator
    function _onlyApprovedCreator() internal virtual {
        if (msg.sender == owner()) return;
        if (additionalCreatorEnabled[msg.sender]) return;
        revert NotAuthorised();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IKOAccessControlsLookup} from "./interfaces/IKOAccessControlsLookup.sol";
import {IKODASettings} from "./interfaces/IKODASettings.sol";
import {ZeroAddress} from "./errors/KODAErrors.sol";
import {Konstants} from "./Konstants.sol";

/// @title KnownOrigin Generalised Marketplace Settings For KODA Version 4 and beyond
/// @notice KODASettings grants flexibility in commission collected at primary and secondary point of sale
contract KODASettings is UUPSUpgradeable, Konstants, IKODASettings {
    /// @notice Address of the contract that defines who can update settings
    IKOAccessControlsLookup public accessControls;

    /// @notice Fee applied to all primary sales
    uint256 public platformPrimaryCommission;

    /// @notice Fee applied to all secondary sales
    uint256 public platformSecondaryCommission;

    /// @notice Address of the platform handler
    address public platform;

    /// @notice Base KO API endpoint
    string public baseKOApi;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external initializer {
        if (_platform == address(0)) revert ZeroAddress();
        if (address(_accessControls) == address(0)) revert ZeroAddress();

        __UUPSUpgradeable_init();

        platformPrimaryCommission = 15_00000;
        platformSecondaryCommission = 2_50000;

        platform = _platform;
        baseKOApi = _baseKOApi;
        accessControls = _accessControls;
    }

    /// @dev Only admins can trigger smart contract upgrades
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformPrimaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION)
            revert MaxCommissionExceeded();
        platformPrimaryCommission = _percentage;
        emit PlatformPrimaryCommissionUpdated(_percentage);
    }

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformSecondaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION)
            revert MaxCommissionExceeded();
        platformSecondaryCommission = _percentage;
        emit PlatformSecondaryCommissionUpdated(_percentage);
    }

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_platform == address(0)) revert ZeroAddress();
        platform = _platform;
        emit PlatformUpdated(_platform);
    }

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        baseKOApi = _baseKOApi;
        emit BaseKOAPIUpdated(_baseKOApi);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {ITokenUriResolver} from "../../interfaces/ITokenUriResolver.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODAEditions is IERC721Metadata, IERC2981 {
    error BatchOrUnknownEdition();
    error EditionDoesNotExist();
    error EditionSizeExceeded();
    error InvalidRange();
    error InvalidEditionSize();
    error InvalidMintQuantity();
    error InvalidRecipient();
    error NotAuthorised();
    error TokenAlreadyMinted();
    error TokenDoesNotExist();

    /// @dev emitted when a new edition is created
    event EditionCreated(uint256 indexed _editionId);

    /// @dev emitted when the creator address for an edition is updated
    event EditionCreatorUpdated(uint256 indexed _editionId, address _creator);

    /// @dev emitted when the owner updates the edition override for secondary royalty
    event EditionRoyaltyPercentageUpdated(
        uint256 indexed _editionId,
        uint256 _percentage
    );

    /// @dev emitted when edition sales are enabled/disabled
    event EditionSalesDisabledUpdated(
        uint256 indexed _editionId,
        bool _disabled
    );

    /// @dev emitted when the edition metadata URI is updated
    event EditionURIUpdated(uint256 indexed _editionId);

    /// @dev emitted when the external token metadata URI resolver is updated
    event TokenURIResolverUpdated(address indexed _tokenUriResolver);

    /// @dev Struct defining the properties of an edition stored internally
    struct Edition {
        uint32 editionSize; // on-chain edition size
        bool isOpenEdition; // true if not all tokens were minted at creation
        string uri; // the referenced metadata
    }

    /// @dev Struct defining the full property set of an edition exposed externally
    struct EditionDetails {
        address owner;
        address creator;
        uint256 editionId;
        uint256 mintedCount;
        uint256 size;
        bool isOpenEdition;
        string uri;
    }

    /// @dev struct defining the ownership record of an edition
    struct EditionOwnership {
        uint256 editionId;
        address editionOwner;
    }

    /// @dev returns the creator address for an edition used to indicate if the NFT creator is different to the contract creator/owner
    function editionCreator(uint256 _editionId) external view returns (address);

    /// @dev returns the full set of properties for an edition, see {EditionDetails}
    function editionDetails(
        uint256 _editionId
    ) external view returns (EditionDetails memory);

    /// @dev returns whether the edition exists or not
    function editionExists(uint256 _editionId) external view returns (bool);

    /// @dev returns the maximum possible token ID that can be minted in an edition
    function editionMaxTokenId(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the number of tokens currently minted in an edition
    function editionMintedCount(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the owner of an edition, by default this will be the contract owner at the time the edition was first created
    function editionOwner(uint256 _editionId) external view returns (address);

    /// @dev returns the royalty percentage used for secondary sales of an edition
    function editionRoyaltyPercentage(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns a boolean indicating whether sales are disabled or not for an edition
    function editionSalesDisabled(
        uint256 _editionId
    ) external view returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOut(
        uint256 _editionId
    ) external view returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (bool);

    /// @dev returns the size (the maximum number of tokens that can be minted) of an edition
    function editionSize(uint256 _editionId) external view returns (uint256);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not
    function editionSoldOut(uint256 _editionId) external view returns (bool);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not in a range
    function editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (bool);

    /// @dev returns the metadata URI for an edition
    function editionURI(
        uint256 _editionId
    ) external view returns (string memory);

    /// @dev returns the edition creator address for the edition that a token with `_tokenId` belongs to
    function tokenEditionCreator(
        uint256 _tokenId
    ) external view returns (address);

    /// @dev returns the full set of properties of the edition that token `_tokenId` belongs to, see {EditionDetails}
    function tokenEditionDetails(
        uint256 _tokenId
    ) external view returns (EditionDetails memory);

    /// @dev returns the ID of an edition that a token with ID `_tokenId` belongs to
    function tokenEditionId(uint256 _tokenId) external view returns (uint256);

    /// @dev returns the size of the edition that a token with `_tokenId` belongs to
    function tokenEditionSize(uint256 _tokenId) external view returns (uint256);

    /// @dev returns a boolean indicating whether an external token metadata URI resolver is active or not
    function tokenUriResolverActive() external view returns (bool);

    /// @dev used to execute a simultaneous transfer of multiple tokens with IDs `_tokenIds`
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external;

    /// @dev used to enabled/disable sales of an edition
    function toggleEditionSalesDisabled(uint256 _editionId) external;

    /// @dev used to update the address of the creator associated with the works of an edition
    function updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) external;

    /// @dev used to update the royalty percentage for external secondary sales of tokens belonging to a specific edition
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) external;

    /// @dev used to set an external token URI resolver for the contract
    function updateTokenURIResolver(
        ITokenUriResolver _tokenUriResolver
    ) external;
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreator {
    error AlreadySet();
    error EditionDisabled();
    error EditionSizeTooLarge();
    error EditionSizeTooSmall();
    error EmptyString();
    error InvalidOwner();
    error IsOpenEdition();
    error OwnerRevoked();
    error PrimarySaleMade();
    error ZeroAddress();

    event EditionSizeUpdated(uint256 indexed _editionId, uint256 _editionSize);
    event EditionFundsHandlerUpdated(
        uint256 indexed _editionId,
        address indexed _handler
    );

    /// @dev Function value can be more easily updated in event of an upgrade
    function version() external pure returns (string memory);

    /// @dev Returns the address that will receive sale proceeds for a given edition
    function editionFundsHandler(
        uint256 _editionId
    ) external view returns (address);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (uint256);

    /// @dev allows the owner or additional minter to mint open edition tokens
    function mintOpenEditionToken(
        uint256 _editionId,
        address _recipient
    ) external returns (uint256);

    /**
     * @dev allows the contract owner or additional minter to mint multiple open edition tokens
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) external;

    /// @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address, setting metadata and a funds handler for this edition
    function createEditionAsCollaboration(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        address _collabFundsHandler,
        string calldata _uri
    ) external returns (uint256 editionId);

    /// @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows the contract owner to create an edition of specified size for lazy minting
    function createOpenEdition(
        uint32 _editionSize,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows the contract owner to create an edition of specified size for lazy minting as a collaboration with another entity, passing in a seperate funds handler for the edition
    function createOpenEditionAsCollaboration(
        uint32 _editionSize,
        address _collabFundsHandler,
        string calldata _uri
    ) external returns (uint256 editionId);

    /// @dev Allows the contract owner to add additional minters if the appropriate minting logic is in place
    function updateAdditionalMinterEnabled(
        address _minter,
        bool _enabled
    ) external;

    /// @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) external;

    /// @dev allows the contract owner to update the number of tokens that can be minted in an edition
    function updateEditionSize(
        uint256 _editionId,
        uint32 _editionSize
    ) external;

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(
        uint256 _editionId,
        string calldata _newURI
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IERC721KODAEditions} from "./interfaces/IERC721KODAEditions.sol";
import {ITokenUriResolver} from "../interfaces/ITokenUriResolver.sol";

import {KODABaseUpgradeable} from "../KODABaseUpgradeable.sol";

/**
 * @author KnownOrigin Labs - https://knownorigin.io/
 * @dev Base contract which extends the ERC721 NFT standards with edition-based minting logic
 */
abstract contract ERC721KODAEditions is
    KODABaseUpgradeable,
    IERC721KODAEditions
{
    // * ERC721 State * //

    bytes4 internal constant ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    /// @dev Mapping of tokenId => owner - only set on first transfer (after mint) such as a primary sale and/or gift
    mapping(uint256 => address) internal _owners;

    /// @dev Mapping of owner => number of tokens owned
    mapping(address => uint256) internal _balances;

    /// @dev Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @dev Mapping of tokenId => approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // * Custom State * //

    /// @dev ownership of latest editions recorded when contract ownership is transferred
    EditionOwnership[] internal _editionOwnerships;

    /// @notice Token URI resolver
    ITokenUriResolver public tokenUriResolver;

    /// @notice Original deployer of the 721 NFT
    address public originalDeployer;

    /// @dev tokens are minted in batches - the first token ID used is representative of the edition ID
    mapping(uint256 => Edition) internal _editions;

    /// @dev Given an edition ID, if the result is not address(0) then a specific creator has been set for an edition
    mapping(uint256 => address) internal _editionCreator;

    /// @dev The number of tokens minted from an open edition
    mapping(uint256 => uint256) internal _editionMintedCount;

    /// @dev For any given edition ID will be non zero if set by the contract owner for an edition
    mapping(uint256 => uint256) internal _editionRoyaltyPercentage;

    /// @dev Allows a creator to disable sales of their edition
    mapping(uint256 => bool) internal _editionSalesDisabled;

    /// @dev determines the maximum size and the next starting ID for each edition i.e. each edition starts at a multiple of 100,000
    uint32 public constant MAX_EDITION_SIZE = 100_000;

    /**
     * @notice Next Edition ID
     * @dev the ID of the edition that will be created next
     */
    uint256 public nextEditionId;

    // ************* //
    // * MODIFIERS * //
    // ************* //

    modifier onlyEditionOwner(uint256 _editionId) {
        _onlyEditionOwner(_editionId);
        _;
    }

    modifier onlyExistingEdition(uint256 _editionId) {
        _onlyExistingEdition(_editionId);
        _;
    }

    modifier onlyExistingToken(uint256 _tokenId) {
        _onlyExistingToken(_tokenId);
        _;
    }

    modifier onlyOpenEdition(uint256 _editionId) {
        _onlyOpenEdition(_editionId);
        _;
    }

    modifier onlyOpenEditionFromTokenId(uint256 _tokenId) {
        uint256 editionId = _tokenEditionId(_tokenId);
        _onlyOpenEdition(editionId);
        _;
    }

    modifier validateEdition(uint256 _editionId) {
        _validateEdition(_editionId);
        _;
    }

    // ********** //
    // * PUBLIC * //
    // ********** //

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *      function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return uint256 The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "Invalid owner");
        return _owner == owner() ? _balances[_owner] - 1 : _balances[_owner];
    }

    // * Approvals * //

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *      Throws unless `msg.sender` is the current NFT owner, or an authorized
     *      operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external override {
        address owner = ownerOf(_tokenId);
        require(_approved != owner, "Approved is owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Invalid sender"
        );

        _approve(owner, _approved, _tokenId);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return address The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(
        uint256 _tokenId
    ) public view override returns (address) {
        require(
            _exists(_tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[_tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *         all of `msg.sender`"s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *      multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override {
        require(_msgSender() != _operator, "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    // * Transfers * //

    /**
     * @notice An extension to the default ERC721 behaviour, derived from ERC-875.
     * @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
     * @param _from the address to transfer tokens from
     * @param _to the address to transfer tokens to
     * @param _tokenIds list of token IDs to transfer
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) public override {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _safeTransferFrom(_from, _to, _tokenIds[i], bytes(""));
        }
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *      operator, or the approved address for this NFT. Throws if `_from` is
     *      not the current owner. Throws if `_to` is the zero address. Throws if
     *      `_tokenId` is not a valid NFT. When transfer is complete, this function
     *      checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      {onERC721Received} on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *          TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *          THEY MAY BE PERMANENTLY LOST
     *  @dev Throws unless `_msgSender()` is the current owner, an authorized
     *       operator, or the approved address for this NFT. Throws if `_from` is
     *       not the current owner. Throws if `_to` is the zero address. Throws if
     *       `_tokenId` is not a valid NFT.
     *  @param _from The current owner of the NFT
     *  @param _to The new owner
     *  @param _tokenId The NFT to transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _transferFrom(_from, _to, _tokenId);
    }

    // * Editions * //

    /**
     * @notice Edition Creator Address
     * @dev returns the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @return address the address of the creator of the works associated with the edition
     */
    function editionCreator(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (address) {
        return
            _editionCreator[_editionId] == address(0)
                ? editionOwner(_editionId)
                : _editionCreator[_editionId];
    }

    /**
     * @notice Get Edition Details
     * @dev returns the full edition details
     * @param _editionId the ID of the edition
     * @return EditionDetails the full set of properties of the edition
     */
    function editionDetails(
        uint256 _editionId
    )
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (EditionDetails memory)
    {
        return
            EditionDetails(
                editionOwner(_editionId), // edition owner
                editionCreator(_editionId), // edition creator
                _editionId,
                editionMintedCount(_editionId),
                editionSize(_editionId),
                isOpenEdition(_editionId),
                editionURI(_editionId)
            );
    }

    /**
     * @notice Check if an Edition Exists
     * @dev returns whether edition with id `_editionId` exists or not
     * @param _editionId the ID of the edition
     * @return bool does the edition exist
     */
    function editionExists(
        uint256 _editionId
    ) public view override returns (bool) {
        return _editionExists(_editionId);
    }

    /**
     * @notice Maximum Token ID of an Edition
     * @dev returns the last token ID of edition `_editionId` based on the edition's size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum possible token ID
     */
    function editionMaxTokenId(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        return _editionMaxTokenId(_editionId);
    }

    /**
     * @notice Edition Minted Count
     * @dev returns the number of tokens minted for an edition - returns edition size if count is 0 but a token has been minted due to assumed batch mint
     * @param _editionId the id of the edition to get a count for
     * @return uint256 the number of tokens minted in the edition
     */
    function editionMintedCount(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        uint256 count = _editionMintedCount[_editionId];
        if (count > 0) return count;

        if (!_editions[_editionId].isOpenEdition)
            return editionSize(_editionId);

        return 0;
    }

    /**
     * @notice Edition Owner
     * @dev calculates the owner of an edition from recorded ownerships - falls back to current contract owner
     * @param _editionId the id of the edition to get the owner of
     * @return address the address of the edition owner
     */
    function editionOwner(
        uint256 _editionId
    ) public view override returns (address) {
        if (!_editionExists(_editionId)) return address(0);

        uint256 count = _editionOwnerships.length;
        if (count == 0) return owner();

        unchecked {
            // the maximum number of ownerships that need checking = the number of editions from the current one to the end
            uint256 toCheck = (nextEditionId - _editionId) / MAX_EDITION_SIZE;

            uint256 i;
            // if less (or equal) need checking than the number of ownerships recorded, only check the latest ownerships
            if (toCheck < count) {
                i = count - toCheck;
            }

            for (i; i < count; i++) {
                if (_editionId <= _editionOwnerships[i].editionId) {
                    return _editionOwnerships[i].editionOwner;
                }
            }
        }

        return owner();
    }

    /**
     * @notice Edition Royalty Percentage
     * @dev returns the default secondary sale royalty percentage or a stored override value if set
     * @param _editionId the id of the edition to get the royalty percentage for
     * @return uint256 the royalty percentage value for the edition
     */
    function editionRoyaltyPercentage(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        uint256 royaltyOverride = _editionRoyaltyPercentage[_editionId];
        return
            royaltyOverride == 0 ? defaultRoyaltyPercentage : royaltyOverride;
    }

    /**
     * @notice Check if Edition Primary Sales are Disabled
     * @dev returns whether or not primary sales of an edition are disabled
     * @param _editionId the ID of the edition
     * @return bool primary sales are disabled
     */
    function editionSalesDisabled(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSalesDisabled[_editionId];
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOut(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSalesDisabled[_editionId] || _editionSoldOut(_editionId);
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return
            _editionSalesDisabled[_editionId] ||
            _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition Size
     * @dev returns the maximum number of tokens that CAN BE minted in an edition
     *
     * - see {editionMintedCount} for the number of tokens minted in an edition so far
     *
     * @param _editionId the id of the edition
     * @return uint256 the size of the edition
     */
    function editionSize(
        uint256 _editionId
    ) public view override returns (uint256) {
        return _editions[_editionId].editionSize;
    }

    /**
     * @notice Is the Edition Sold Out
     * @dev returns whether on not primary sales are still possible for an edition
     * @param _editionId the ID of the edition
     * @return bool the edition is sold out
     */
    function editionSoldOut(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSoldOut(_editionId);
    }

    /**
     * @notice Is the Edition Sold Out after a specific tokenId
     * @dev returns whether on not all tokens have been sold or transferred after `_startId`
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool the edition is sold out from the startId pointer
     */
    function editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition URI
     * @dev returns the URI for edition metadata - possibly the metadata for the first token if an external resolver is set
     * @param _editionId the ID of the edition
     * @return string the URI for the edition metadata
     */
    function editionURI(
        uint256 _editionId
    )
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (string memory)
    {
        // Here we are checking only that the edition has a edition level resolver - there may be a overridden token level resolver
        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(_editionId, 0)
        ) {
            return tokenUriResolver.tokenURI(_editionId, 0);
        }

        return _editions[_editionId].uri;
    }

    /**
     * @notice Is Edition Open?
     * @dev returns whether or not an edition has tokens available to be minted
     * @param _editionId the ID of the edition check
     * @return bool is the edition open
     */
    function isOpenEdition(uint256 _editionId) public view returns (bool) {
        return editionMintedCount(_editionId) < editionSize(_editionId);
    }

    // * Tokens * //

    /**
     * @notice Check the Existence of a Token
     * @dev returns whether or not a token exists with ID `_tokenID`
     * @param _tokenId the ID of the token
     * @return bool the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return address The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        uint256 editionId = _tokenEditionId(_tokenId);
        address owner = _ownerOf(_tokenId, editionId);
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    /**
     * @notice Creator of the Works of an Edition Token
     * @dev returns the creator associated with the works of an edition
     * @param _tokenId the ID of the token in an edition
     * @return address the address of the creator
     */
    function tokenEditionCreator(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (address) {
        return editionCreator(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get Edition Details for a Token
     * @dev returns the full edition details for a token
     * @param _tokenId the ID of a token in an edition
     * @return EditionDetails the full set of properties for the edition
     */
    function tokenEditionDetails(
        uint256 _tokenId
    )
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (EditionDetails memory)
    {
        return editionDetails(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the Edition ID of a Token
     * @dev returns the ID of the edition the token belongs to
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the ID of the edition the token belongs to
     */
    function tokenEditionId(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (uint256) {
        return _tokenEditionId(_tokenId);
    }

    /**
     * @notice Get the Size of an Edition for a Token
     * @dev returns the size of the edition the token belongs to, see {editionSize}
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the size of the edition the token belongs to
     */
    function tokenEditionSize(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (uint256) {
        return editionSize(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the URI of the Metadata for a Token
     * @dev returns the URI of the token metadata or the metadata for the edition the token belongs to if an external resolver is not set
     * @param _tokenId the ID of a token in an edition
     * @return string the URI of the token or edition metadata
     */
    function tokenURI(
        uint256 _tokenId
    ) public view onlyExistingToken(_tokenId) returns (string memory) {
        uint256 editionId = _tokenEditionId(_tokenId);

        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(editionId, _tokenId)
        ) {
            return tokenUriResolver.tokenURI(editionId, _tokenId);
        }

        return _editions[editionId].uri;
    }

    /**
     * @notice Token URI Resolver Active
     * @dev return whether or not an external URI resolver has been set
     * @return bool is a token URI resolver set
     */
    function tokenUriResolverActive() public view override returns (bool) {
        return address(tokenUriResolver) != address(0);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Enable/Disable Edition Sales
     * @dev allows the owner of the contract to enable/disable primary sales of an edition
     * @param _editionId the ID of the edition to enable/disable primary sales of
     *
     * Emits {EditionSalesDisabledUpdated}
     */
    function toggleEditionSalesDisabled(
        uint256 _editionId
    ) public override onlyEditionOwner(_editionId) {
        bool disabled = !_editionSalesDisabled[_editionId];
        _editionSalesDisabled[_editionId] = disabled;
        emit EditionSalesDisabledUpdated(_editionId, disabled);
    }

    /**
     * @notice Update Edition Creator
     * @dev allows the contact owner to provide edition attribution to another address
     * @param _editionId the ID of the edition to set a creator for
     * @param _creator the address of the creator associated with the works of an edition
     *
     * Emits {EditionCreatorUpdated}
     */
    function updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) public override onlyOwner {
        _updateEditionCreator(_editionId, _creator);
    }

    /**
     * @notice Update Secondary Royalty Percentage for an Edition
     * @dev allows the contract owner to set an edition level override for secondary royalties of a specific edition
     * @param _editionId the ID of the edition
     * @param _percentage the secondary royalty percentage using the same precision as {MODULO}
     *
     * Emits {EditionRoyaltyPercentageUpdated}
     */
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) public override onlyEditionOwner(_editionId) {
        if (_percentage > MAX_ROYALTY_PERCENTAGE)
            revert MaxRoyaltyPercentageExceeded();
        _editionRoyaltyPercentage[_editionId] = _percentage;
        emit EditionRoyaltyPercentageUpdated(_editionId, _percentage);
    }

    /**
     * @notice Update Token URI Resolver
     * @dev allows the contract owner to update the token URI resolver for editions and tokens
     * @param _tokenUriResolver address of the token URI resolver contract
     *
     * Emits {TokenURIResolverUpdated}
     */
    function updateTokenURIResolver(
        ITokenUriResolver _tokenUriResolver
    ) public override onlyOwner {
        tokenUriResolver = _tokenUriResolver;
        emit TokenURIResolverUpdated(address(_tokenUriResolver));
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Editions * //

    /**
     * @dev internal function for creating editions
     *
     * Requirements:
     *
     * - the parent contract should implement logic to decide who can use this
     * - `_editionSize` must not be 0 or greater than {Konstants-MAX_EDITION_SIZE}
     * - `_mintQuantity` must not be greater than `_editionSize`
     * - `_recipient` must not be `address(0)` if `mintQuantity` is greater than 0
     *
     * @param _editionSize the maximum number of tokens that can be minted in the edition
     * @param _mintQuantity the number of tokens to mint immediately
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional address to attribute the works of the edition to
     * @param _uri the URI for the edition metadata
     * @return uint256 the ID of the new edition that is created
     *
     * Emits {EditionCreated}
     * Emits {EditionCreatorUpdated} if a `_creator` is not `address(0)`
     * Emits {Transfer} for any tokens that are minted
     */
    function _createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) internal virtual returns (uint256) {
        if (_editionSize == 0 || _editionSize > MAX_EDITION_SIZE)
            revert InvalidEditionSize();
        if (_mintQuantity > _editionSize) revert InvalidMintQuantity();
        if (_recipient == address(0)) revert InvalidRecipient();

        // configure start token ID
        uint256 editionId = nextEditionId;
        bool isOpen = _mintQuantity < _editionSize;

        unchecked {
            nextEditionId += MAX_EDITION_SIZE;
        }

        _editions[editionId] = Edition(_editionSize, isOpen, _uri);

        emit EditionCreated(editionId);

        if (_creator != address(0)) {
            _updateEditionCreator(editionId, _creator);
        }

        if (_mintQuantity > 0) {
            if (isOpen) _editionMintedCount[editionId] = _mintQuantity;
            _mintConsecutive(_recipient, _mintQuantity, editionId);
        }

        return editionId;
    }

    /**
     * @dev calculates if an edition exists
     * - edition size is used to calculate the existence of an edition
     * - an existing edition can't have its size set to 0
     *
     * @param _editionId the ID of the edition
     * @return bool the edition exists
     */
    function _editionExists(uint256 _editionId) internal view returns (bool) {
        return editionSize(_editionId) > 0;
    }

    /**
     * @dev calculates the maximum token ID for an edition based on the edition's ID and size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum token ID that can be minted for the edition
     */
    function _editionMaxTokenId(
        uint256 _editionId
    ) internal view returns (uint256) {
        return _editionId + editionSize(_editionId) - 1;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted
     * @param _editionId the ID of the edition
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOut(
        uint256 _editionId
    ) internal view virtual returns (bool) {
        // isOpenEdition returns true if NOT ALL tokens in an edition have been minted, so sold out should always be false
        if (isOpenEdition(_editionId)) {
            return false;
        }

        // even for editions initially created as open,
        // we should check each token for an owner once all tokens have been minted
        // since they may have been minted by the owner to sell
        unchecked {
            for (
                uint256 tokenId = _editionId;
                tokenId <= _editionMaxTokenId(_editionId);
                tokenId++
            ) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted in a range
     * @param _editionId the ID of the edition
     * @param _startId the tokenId to start checking from
     * @param _quantity the number of tokens to check - to check a smaller range
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId,
        uint256 _quantity
    ) internal view virtual returns (bool) {
        if (_startId < _editionId) revert InvalidRange();

        uint256 maxTokenId = _editionMaxTokenId(_editionId);
        if (_startId > maxTokenId) revert InvalidRange();

        // if quantity 0, check all the way to the end of the edition
        uint256 finishId = _quantity == 0
            ? maxTokenId
            : _startId + _quantity - 1;

        // don't check beyond maxTokenId
        if (finishId > maxTokenId) finishId = maxTokenId;

        unchecked {
            for (uint256 tokenId = _startId; tokenId <= finishId; tokenId++) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev minting of multiple tokens of open edition `_editionId` to the edition owner
     * @dev optimised by not storing token ownership address which is accounted for in _ownerOf()
     *
     * Requirements:
     *
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _editionId the edition that the token is a member of
     * @param _quantity the number of tokens to mint
     */
    function _mintMultipleOpenEditionToOwner(
        uint256 _editionId,
        uint256 _quantity
    ) internal virtual {
        if (!_editions[_editionId].isOpenEdition)
            revert BatchOrUnknownEdition();
        address _owner = editionOwner(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];
            if (mintedCount + _quantity > editionSize(_editionId))
                revert EditionSizeExceeded();

            _editionMintedCount[_editionId] += _quantity;
            _balances[_owner] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            uint256 firstTokenId = _editionId + mintedCount;
            for (uint256 i = 0; i < _quantity; i++) {
                _mintTransferToOwner(_owner, firstTokenId + i);
            }
        }
    }

    /**
     * @dev mints a single token of open edition `_editionId` to `_recipient`
     *
     * Requirements:
     *
     * - recipient is not the zero address
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _recipient the address to transfer the minted token to
     * @param _editionId the edition that the token is a member of
     * @return uint256 the minted token ID
     */
    function _mintSingleOpenEditionTo(
        uint256 _editionId,
        address _recipient
    ) internal virtual returns (uint256) {
        if (_recipient == address(0)) revert InvalidRecipient();
        _onlyOpenEdition(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];

            // Get next token ID for sale
            uint256 tokenId = _editionId + mintedCount;

            _editionMintedCount[_editionId] += 1;

            _mintSingle(_recipient, tokenId);
            return tokenId;
        }
    }

    /**
     * @dev sets the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @param _creator the address of the creator
     *
     * Emits {EditionCreatorUpdated}
     */
    function _updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) internal virtual {
        _editionCreator[_editionId] = _creator;
        emit EditionCreatorUpdated(_editionId, _creator);
    }

    // * Tokens * //

    /**
     * @dev Approve `_approved` to operate on `_tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address _owner,
        address _approved,
        uint256 _tokenId
    ) internal virtual {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook that is called after any token transfer. This includes minting and burning
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /**
     * @dev returns the existence of a token by checking for an owner
     * @param _tokenId the token ID to check
     * @return bool the token exists
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf(_tokenId, _tokenEditionId(_tokenId)) != address(0);
    }

    /**
     * @dev returns the address of the owner of a token
     * - Newly created editions and its tokens minted to a creator don't have the owner set until the token is sold on the primary market
     * - Therefore, if internally an edition exists and owner of token is zero address, then creator still owns the token
     * - Otherwise, the token owner is returned or the zero address if the token does not exist
     *
     * @param _tokenId the ID of the token to check
     * @param _editionId the ID of the edition the token belongs to
     * @return address the address of the token owner
     */
    function _ownerOf(
        uint256 _tokenId,
        uint256 _editionId
    ) internal view virtual returns (address) {
        // If an owner assigned
        address _owner = _owners[_tokenId];
        if (_owner != address(0)) {
            return _owner;
        }

        address _editionOwner = editionOwner(_editionId);

        if (_editionOwner != address(0)) {
            // if not open edition, return owner
            if (!_editions[_editionId].isOpenEdition) {
                return _editionOwner;
            }

            // if open edition, return owner below minted count, return 0 above minted count
            if (_tokenId < _editionId + _editionMintedCount[_editionId]) {
                return _editionOwner;
            }
        }

        return address(0);
    }

    /**
     * @dev calculates the edition ID using the token ID given and MAX_EDITION_SIZE
     * @param _tokenId the ID of the token to get edition ID for
     * @return uint256 the ID of the edition the token is from
     */
    function _tokenEditionId(uint256 _tokenId) internal pure returns (uint256) {
        return (_tokenId / MAX_EDITION_SIZE) * MAX_EDITION_SIZE;
    }

    // * Contract Ownership * //

    /// @dev override {Ownable-_transferOwnership} to record the old owner as the current edition owner if not already recorded
    function _transferOwnership(address _newOwner) internal virtual override {
        // record the edition owner of the most recent edition
        if (nextEditionId > MAX_EDITION_SIZE) {
            _recordLatestEditionOwnership(owner());
        }

        super._transferOwnership(_newOwner);
    }

    // * Validators * //

    function _onlyEditionOwner(uint256 _editionId) internal view {
        if (msg.sender == editionOwner(_editionId)) return;
        revert NotAuthorised();
    }

    /// @dev reverts if the edition does not exist
    function _onlyExistingEdition(uint256 _editionId) internal view {
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
    }

    /// @dev reverts if the token does not exist
    function _onlyExistingToken(uint256 _tokenId) internal view {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();
    }

    /// @dev reverts if the edition is not open
    function _onlyOpenEdition(uint256 _editionId) internal view {
        if (!isOpenEdition(_editionId)) revert BatchOrUnknownEdition();
    }

    /// @dev reverts if the edition is not valid
    function _validateEdition(uint256 _editionId) internal view virtual {
        _onlyExistingEdition(_editionId);
    }

    // *********** //
    // * PRIVATE * //
    // *********** //

    // * Edition Ownership * //

    /**
     * @dev records the editionOwnership of the most recent edition if not already recorded
     *
     * - must only be used when at least one edition has been minted
     */
    function _recordLatestEditionOwnership(address _editionOwner) private {
        uint256 count = _editionOwnerships.length;
        uint256 _editionId = nextEditionId - MAX_EDITION_SIZE;

        if (count == 0) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
            return;
        }

        uint256 lastOwnershipId = _editionOwnerships[count - 1].editionId;
        bool ownershipNotRecorded = lastOwnershipId != _editionId;
        if (ownershipNotRecorded) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
        }
    }

    // * Minting * //

    /**
     * @dev Mints multiple consecutive tokens starting at and including the first specified ID - must be pre-validated
     * @param _recipient address to mint to
     * @param _quantity the number of tokens to mint
     * @param _firstTokenId the token to start minting from
     */
    function _mintConsecutive(
        address _recipient,
        uint256 _quantity,
        uint256 _firstTokenId
    ) private {
        unchecked {
            _balances[_recipient] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            if (_recipient == owner()) {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransferToOwner(_recipient, _firstTokenId + i);
                }
            } else {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransfer(_recipient, _firstTokenId + i);
                }
            }
        }
    }

    /**
     * @notice Mint a Single Token ID
     * @dev Mint a token with the specified tokenId and update the recipient balance - must be pre-validated
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintSingle(address _recipient, uint256 _tokenId) private {
        unchecked {
            _balances[_recipient] += 1; // unlikely to exceed 2 ^ 256 - 1
            _mintTransfer(_recipient, _tokenId);
        }
    }

    /**
     * @notice Mint Transfer
     * @dev Transfer logic of minting a token - should be pre-validated and update balance in parent function
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintTransfer(address _recipient, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _recipient, _tokenId);
        _owners[_tokenId] = _recipient;
        emit Transfer(address(0), _recipient, _tokenId);
        _afterTokenTransfer(address(0), _recipient, _tokenId);
    }

    /**
     * @notice Mint Transfer To Owner
     * @dev Transfer logic of minting a token to the edition owner - should be pre-validated and update balance in parent function
     *
     * Requirements:
     *
     * - `_owner` must only ever be the owner of the edition the token belongs to
     *
     * @param _owner address of the edition owner
     * @param _tokenId id of the token to mint
     */
    function _mintTransferToOwner(address _owner, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _owner, _tokenId);
        emit Transfer(address(0), _owner, _tokenId);
        _afterTokenTransfer(address(0), _owner, _tokenId);
    }

    // * Token Transfers * //

    /// @dev performs a transfer of a token and checks for a correct response if the `_to` is a contract
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private {
        _transferFrom(_from, _to, _tokenId);

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            require(selector == ERC721_RECEIVED, "Invalid selector");
        }
    }

    /**
     * @dev custom implementation of logic to transfer a token from one address to another
     *
     * Requirements:
     *
     * - `_to` must not be the zero address - we have custom logic which is optimised for minting to the contract owner
     * - the token must have an owner i.e. CAN NOT BE USED FOR MINTING
     * - the msg.sender must be the the current token owner, approved for all, or approved for the specific token
     * - should call before and after transfer hooks
     * - should clear any existing token approval
     * - should adjust the balances of the existing and new token owner
     *
     * Emits {Approval}
     * Emits {Transfer}
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        // enforce not being able to send to zero as we have explicit rules what a minted but unbound owner is
        if (_to == address(0)) revert InvalidRecipient();

        // Ensure the owner is the sender
        address owner = _ownerOf(_tokenId, _tokenEditionId(_tokenId));
        if (owner == address(0)) revert TokenDoesNotExist();
        require(_from == owner, "Owner mismatch");

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);
        require(
            spender == owner || // sending to myself
                isApprovedForAll(owner, spender) || // is approved to send any behalf of owner
                approvedAddress == spender, // is approved to move this token ID
            "Invalid spender"
        );

        // do before transfer check
        _beforeTokenTransfer(_from, _to, _tokenId);

        // Ensure approval for token ID is cleared
        _approve(owner, address(0), _tokenId);

        unchecked {
            // Modify balances
            _balances[_from] -= 1;
            _balances[_to] += 1;
        }
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);

        // do after transfer check
        _afterTokenTransfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(
        uint256 _index,
        address _account,
        bytes32[] calldata _merkleProof
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "./IKOAccessControlsLookup.sol";

interface IKODASettings {
    error MaxCommissionExceeded();
    error OnlyAdmin();
    event PlatformPrimaryCommissionUpdated(uint256 _percentage);
    event PlatformSecondaryCommissionUpdated(uint256 _percentage);
    event PlatformUpdated(address indexed _platform);
    event BaseKOAPIUpdated(string _baseKOApi);

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external;

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformPrimaryCommission(uint256 _percentage) external;

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformSecondaryCommission(uint256 _percentage) external;

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external;

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

error AlreadyListed();
error AlreadySet();
error EditionDisabled();
error EditionNotListed();
error EditionSalesDisabled();
error EmptyString();
error InvalidListing();
error InvalidOwner();
error InvalidPrice();
error InvalidToken();
error IsOpenEdition();
error OnlyAdmin();
error OnlyVerifiedArtist();
error OwnerRevoked();
error PrimarySaleMade();
error TooEarly();
error TransferFailed();
error ZeroAddress();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Konstants {
    /// @notice Maximum Platform Commission for Primary and Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_PLATFORM_COMMISSION = 50_00000;

    /// @notice Maximum Royalty Percentage for Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_ROYALTY_PERCENTAGE = 50_00000;

    /// @notice Denominator used for percentage calculations
    /// @dev precision 100.00000%
    uint24 public constant MODULO = 100_00000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokenUriResolver {
    /// @notice Return the edition or token level URI - token level trumps edition level if found
    function tokenURI(
        uint256 _editionId,
        uint256 _tokenId
    ) external view returns (string memory);

    /// @notice Do we have an edition level or token level token URI resolver set
    function isDefined(
        uint256 _editionId,
        uint256 _tokenId
    ) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Konstants} from "./Konstants.sol";
import {IKODABaseUpgradeable} from "./interfaces/IKODABaseUpgradeable.sol";

/**
 * @dev Base contract for KnownOrigin Creator NFT minting contracts
 *
 * - requires IKODABaseUpgradable interface for errors and events
 * - requires OpenZeppelin upgradable contracts to make inheriting contracts ownable and pausable
 *
 * - includes storage of default secondary marketplace royalties and additionally enabled minting addresses managed by the owner
 */
abstract contract KODABaseUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Konstants,
    IKODABaseUpgradeable
{
    /**
     * @notice Default Royalty Percentage for Secondary Sales
     * @dev default percentage value used to calculate royalty consideration on secondary sales stored with the same precision as `MODULO`
     */
    uint256 public defaultRoyaltyPercentage;

    // * Upgradeable Init * //

    /**
     * @notice Initialise the base contract with the default royalty percentage
     * @dev the inheriting contract must call otherwise the secondary royalty will be zero
     * @param _initialRoyaltyPercentage percentage to initially set the contract default royalty
     */
    function __KODABase_init(uint256 _initialRoyaltyPercentage) internal {
        __ReentrancyGuard_init();
        _updateDefaultRoyaltyPercentage(_initialRoyaltyPercentage);
    }

    // * OWNER * //

    /// @notice Allows the owner to pause some contract actions
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Allows the owner to unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set the default royalty percentage to `_percentage`
     * @dev allows the owner to set {defaultRoyaltyPercentage}
     * @param _percentage the value to set with the same precision as {KODASettings-MODULO}
     */
    function updateDefaultRoyaltyPercentage(
        uint256 _percentage
    ) external onlyOwner {
        _updateDefaultRoyaltyPercentage(_percentage);
    }

    // * INTERNAL * //

    /// @dev Internal method for updating the the secondary royalty percentage used for calculating royalty for external marketplaces
    function _updateDefaultRoyaltyPercentage(uint256 _percentage) internal {
        if (_percentage > MAX_ROYALTY_PERCENTAGE)
            revert MaxRoyaltyPercentageExceeded();
        defaultRoyaltyPercentage = _percentage;
        emit DefaultRoyaltyPercentageUpdated(_percentage);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev required interface for the base contract for KnownOrigin Creator Contracts
 */
interface IKODABaseUpgradeable {
    error MaxRoyaltyPercentageExceeded();

    /// @dev Emitted when additional minter addresses are enabled or disabled
    event AdditionalMinterEnabled(address indexed _minter, bool _enabled);

    /// @dev Emitted when additional creator addresses are enabled or disabled
    event AdditionalCreatorEnabled(address indexed _creator, bool _enabled);

    /// @dev Emitted when the owner updates the default secondary royalty percentage
    event DefaultRoyaltyPercentageUpdated(uint256 _percentage);

    /// @dev Allows the owner to pause some contract actions
    function pause() external;

    /// @dev Allows the owner to unpause
    function unpause() external;

    /// @dev Allows the contract owner to update the default secondary sale royalty percentage
    function updateDefaultRoyaltyPercentage(uint256 _percentage) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {ERC721KODACreator} from "../ERC721KODACreator.sol";
import {IERC721KODACreatorWithBuyItNow} from "../interfaces/IERC721KODACreatorWithBuyItNow.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice ERC721 KODA Creator with Embedded Primary and Secondary Buy It Now Marketplace
contract ERC721KODACreatorWithBuyItNow is
    ERC721KODACreator,
    IERC721KODACreatorWithBuyItNow
{
    /// @notice Edition ID -> Listing Metadata
    mapping(uint256 => EditionListing) public editionListing;

    /// @notice Token ID -> Owner Address -> Listing Metadata
    mapping(uint256 => mapping(address => TokenListing)) public tokenListing;

    // ********** //
    // * PUBLIC * //
    // ********** //

    /// @inheritdoc ERC721KODACreator
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IERC721KODACreatorWithBuyItNow).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // * Marketplace * //

    /**
     * @notice Buy Edition Token
     * @dev allows the purchase of the next available token for sale from an edition listing
     *
     * Requirements:
     *
     * - the listing must exist
     * - the value sent must be equal to the listing price
     * - the listing must be active i.e. the current time must be after the listing start time
     *
     * @param _editionId the ID of the edition to purchase a token from
     * @param _recipient the address that should receive the token purchased
     */
    function buyEditionToken(
        uint256 _editionId,
        address _recipient
    ) external payable override whenNotPaused nonReentrant {
        EditionListing storage listing = editionListing[_editionId];
        if (listing.price == 0) revert InvalidListing();
        if (msg.value != listing.price) revert InvalidPrice();
        if (block.timestamp < listing.startDate) revert TooEarly();
        if (listing.endDate > 0 && block.timestamp > listing.endDate)
            revert TooLate();

        // when owner has renounced ownership, then the transfer will fail but nicer to fail early
        address _owner = owner();
        if (_owner == address(0)) revert EditionSalesDisabled();

        // get the next token ID
        uint256 tokenId = _facilitateNextPrimarySale(_editionId, _recipient);

        address platform = kodaSettings.platform();
        uint256 primaryPercentageForPlatform = kodaSettings
            .platformPrimaryCommission();
        uint256 platformProceeds = (msg.value * primaryPercentageForPlatform) /
            MODULO;

        // Where platform primary commission is zero from the settings, we don't need to execute the transaction
        bool success;
        if (platformProceeds > 0) {
            (success, ) = platform.call{value: platformProceeds}("");
            if (!success) revert TransferFailed();
        }

        // send all the funds to the handler - KO is part of this
        (success, ) = editionFundsHandler(_editionId).call{
            value: msg.value - platformProceeds
        }("");
        if (!success) revert TransferFailed();

        emit BuyNowPurchased(tokenId, msg.sender, _owner, listing.price);
    }

    /**
     * @notice List a Token for sale
     * @dev allows the owner of a token to create a secondary buy it now listing
     * @param _tokenId the ID of the token to list for sale
     * @param _listingPrice the price to list the token for
     * @param _startDate the time the listing is enabled
     * @param _endDate the time the listing is disabled
     */
    function createTokenBuyItNowListing(
        uint256 _tokenId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external override {
        if (_owners[_tokenId] != msg.sender) revert InvalidToken();
        if (_listingPrice == 0) revert InvalidPrice();
        if (tokenListing[_tokenId][msg.sender].price != 0)
            revert AlreadyListed();

        // Store listing data
        tokenListing[_tokenId][msg.sender] = TokenListing(
            msg.sender,
            _listingPrice
        );

        emit ListedTokenForBuyNow(
            msg.sender,
            _tokenId,
            _listingPrice,
            _startDate,
            _endDate
        );
    }

    /**
     * @notice Delist a Token for Sale
     * @dev allows the owner of a token to remove a listing for the token
     * @param _tokenId the ID of the token to delist
     */
    function deleteTokenBuyItNowListing(uint256 _tokenId) external override {
        if (tokenListing[_tokenId][msg.sender].price == 0)
            revert InvalidListing();

        delete tokenListing[_tokenId][msg.sender];

        emit BuyNowTokenDeListed(_tokenId);
    }

    /**
     * @notice Update Token Listing Price
     * @dev allows the owner of a token to update the price
     * @param _tokenId the ID of the token already listed
     * @param _listingPrice the new listing price to set
     */
    function updateTokenBuyItNowListingPrice(
        uint256 _tokenId,
        uint96 _listingPrice
    ) external override {
        if (tokenListing[_tokenId][msg.sender].price == 0)
            revert InvalidListing();
        if (ownerOf(_tokenId) != msg.sender) revert InvalidListing();
        if (_listingPrice == 0) revert InvalidPrice();

        tokenListing[_tokenId][msg.sender].price = _listingPrice;

        emit BuyNowTokenPriceChanged(_tokenId, _listingPrice);
    }

    /**
     * @notice Buy Token
     * @dev allows the purchase of a token listed for sale
     *
     * Requirements:
     *
     * - the listing must exist
     * - the value sent must be equal to the listing price
     *
     * @param _tokenId the ID of the token to purchase
     * @param _recipient the address that should receive the token purchased
     */
    function buyToken(
        uint256 _tokenId,
        address _recipient
    ) external payable override nonReentrant {
        TokenListing storage listing = tokenListing[_tokenId][
            ownerOf(_tokenId)
        ];
        if (listing.price == 0) revert InvalidListing();
        if (listing.price != msg.value) revert InvalidPrice();

        // calculate proceeds owed to platform, creator and seller
        address platform = kodaSettings.platform();
        uint256 secondaryPercentageForPlatform = kodaSettings
            .platformSecondaryCommission();

        uint256 platformProceeds = (msg.value *
            secondaryPercentageForPlatform) / MODULO;
        (address receiver, uint256 royaltyAmount) = royaltyInfo(
            _tokenId,
            msg.value
        );

        // Where platform proceeds is zero due to the settings, no need to call the transfer
        bool success;
        if (platformProceeds > 0) {
            (success, ) = platform.call{value: platformProceeds}("");
            if (!success) revert TransferFailed();
        }

        if (royaltyAmount > 0) {
            (success, ) = receiver.call{value: royaltyAmount}("");
            if (!success) revert TransferFailed();
        }

        // maximum platform commission and royalty percentage are both limited to 50% (max 100% of sale value total)
        // it is also extremely unlikely that they will ever both use the max so no need for additional validation/conditions
        (success, ) = listing.seller.call{
            value: msg.value - royaltyAmount - platformProceeds
        }("");
        if (!success) revert TransferFailed();

        emit BuyNowTokenPurchased(
            _tokenId,
            msg.sender,
            _recipient,
            listing.seller,
            listing.price
        );

        ERC721KODACreatorWithBuyItNow(address(this)).transferFrom(
            listing.seller,
            _recipient,
            _tokenId
        );

        delete tokenListing[_tokenId][ownerOf(_tokenId)];
    }

    /**
     * @notice Get the token listing details for the current token owner
     * @dev Get a token listing just from token ID and not worrying about current owner
     * @param _tokenId the ID of the token
     * @return TokenListing details of the token listing
     */
    function getTokenListing(
        uint256 _tokenId
    ) external view returns (TokenListing memory) {
        return tokenListing[_tokenId][ownerOf(_tokenId)];
    }

    // ********* //
    // * OWNER * //
    // ********* //

    // * Editions * //

    /**
     * @notice List and Edition for Buy It Now
     * @dev allows the edition owner to create a listing to enable sales of tokens from an edition
     *
     * @param _editionId the ID of the edition to create a listing for
     * @param _listingPrice the price to list for
     * @param _startDate the time that the listing becomes active
     * @param _endDate the time the listing is disabled
     */
    function createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) public override onlyEditionOwner(_editionId) {
        _createEditionBuyItNowListing(
            _editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
    }

    /**
     * @notice Delist an Edition for Sale
     * @param _editionId the ID of the edition to delist
     */
    function deleteEditionBuyItNowListing(
        uint256 _editionId
    ) external override onlyEditionOwner(_editionId) {
        if (editionListing[_editionId].price == 0) revert EditionNotListed();
        delete editionListing[_editionId];
        emit BuyNowDeListed(_editionId);
    }

    /**
     * @notice Create and Mint an Edition and List it for Sale
     * @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @param _uri the metadata URI of the edition
     * @return uint256 the ID of the new edition created
     */
    function mintAndListEditionForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        string calldata _uri
    ) external onlyOwner returns (uint256) {
        // Creator override only required if there are sub-minters in addition to contract owner
        uint256 editionId = _createEdition(
            _editionSize,
            _editionSize,
            owner(),
            address(0),
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /**
     * @notice Create and Mint an Edition and List it for Sale
     * @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @param _collabFundsHandler the fund splitting contract
     * @param _uri the metadata URI of the edition
     * @return uint256 the ID of the new edition created
     */
    function mintAndListEditionAsCollaborationForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        address _collabFundsHandler,
        string calldata _uri
    ) external onlyOwner returns (uint256) {
        // Creator override only required if there are sub-minters in addition to contract owner
        uint256 editionId = createEditionAsCollaboration(
            _editionSize,
            _editionSize,
            owner(),
            address(0),
            _collabFundsHandler,
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /// @notice Setup the open edition template and list for buy it now
    /**
     * @notice Create an Open Edition and List it for Sale
     * @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _uri the metadata URI of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @return uint256 the ID of the new edition created
     */
    function setupAndListOpenEdition(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _editionSize
    ) external override onlyOwner returns (uint256) {
        uint256 editionId = _createEdition(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            0,
            owner(),
            address(0),
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /// @notice Setup the open edition template and list for buy it now
    /**
     * @notice Create an Open Edition and List it for Sale
     * @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
     * @param _editionSize the size of the edition
     * @param _uri the metadata URI of the edition
     * @param _listingPrice the price that tokens can be bought for
     * @param _startDate the time that the listing should become active
     * @param _endDate the time the listing is disabled
     * @return uint256 the ID of the new edition created
     * @param _collabFundsHandler the fund splitting contract
     */
    function setupAndListOpenEditionAsCollaboration(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _editionSize,
        address _collabFundsHandler
    ) external onlyOwner returns (uint256) {
        uint256 editionId = createOpenEditionAsCollaboration(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            _collabFundsHandler,
            _uri
        );
        _createEditionBuyItNowListing(
            editionId,
            _listingPrice,
            _startDate,
            _endDate
        );
        return editionId;
    }

    /**
     * @notice Update Edition Listing Price
     * @dev allows the contract owner to update the price of edition tokens listed for sale
     * @param _editionId the ID of the edition already listed
     * @param _listingPrice the new listing price to set
     */
    function updateEditionBuyItNowListingPrice(
        uint256 _editionId,
        uint96 _listingPrice
    ) external override onlyEditionOwner(_editionId) {
        if (editionListing[_editionId].price == 0) revert EditionNotListed();
        if (_listingPrice == 0) revert InvalidPrice();

        // Set price
        editionListing[_editionId].price = _listingPrice;

        // Emit event
        emit BuyNowPriceChanged(_editionId, _listingPrice);
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    /**
     * @dev create a listing to enable sales of tokens from an edition
     *
     * Requirements:
     *
     * - Should have owner validation in parent function
     * - The edition exists
     * - A listing does not already exist for the edition
     * - The listing price is not less than the global minimum
     *
     * @param _editionId the ID of the edition to create a listing for
     * @param _listingPrice the price to list for
     * @param _startDate the time that the listing becomes active
     * @param _endDate the time the listing is disabled
     */
    function _createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) internal {
        if (editionListing[_editionId].price != 0) revert AlreadyListed();
        if (_listingPrice == 0) revert InvalidPrice();

        // automatically set approval for the contract against the edition owner if not already set
        // this is so do they do not need to do it manually in order to sell any editions they list
        if (!_operatorApprovals[msg.sender][address(this)]) {
            _operatorApprovals[msg.sender][address(this)] = true;
            emit ApprovalForAll(msg.sender, address(this), true);
        }

        // Store listing data
        editionListing[_editionId] = EditionListing(
            _listingPrice,
            _startDate,
            _endDate
        );

        emit ListedEditionForBuyNow(_editionId, _listingPrice, _startDate);
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreatorWithBuyItNow {
    error AlreadyListed();
    error EditionNotListed();
    error EditionSalesDisabled();
    error InvalidEdition();
    error InvalidFeesTotal();
    error InvalidListing();
    error InvalidPrice();
    error TooEarly();
    error TooLate();
    error TransferFailed();
    error InvalidToken();

    event BuyNowDeListed(uint256 indexed _editionId);

    event BuyNowPriceChanged(uint256 indexed _editionId, uint256 _price);

    event BuyNowPurchased(
        uint256 indexed _tokenId,
        address _buyer,
        address _currentOwner,
        uint256 _price
    );

    event BuyNowTokenDeListed(uint256 indexed _tokenId);

    event BuyNowTokenPriceChanged(uint256 indexed _tokenId, uint256 _price);

    event BuyNowTokenPurchased(
        uint256 indexed _tokenId,
        address _caller,
        address _recipient,
        address _currentOwner,
        uint256 _price
    );

    // TODO can we squash price and start date into a single slot
    event ListedEditionForBuyNow(
        uint256 indexed _editionId,
        uint96 _price,
        uint128 _startDate
    );

    event ListedTokenForBuyNow(
        address indexed _seller,
        uint256 indexed _tokenId,
        uint96 _price,
        uint128 _startDate,
        uint128 _endDate
    );

    struct EditionListing {
        uint128 price;
        uint128 startDate;
        uint128 endDate;
    }

    struct TokenListing {
        address seller;
        uint128 price;
    }

    /// @dev allows the purchase of the next available token for sale from an edition listing
    function buyEditionToken(
        uint256 _editionId,
        address _recipient
    ) external payable;

    /// @dev allows the owner of a token to create a secondary buy it now listing
    function createTokenBuyItNowListing(
        uint256 _tokenId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external;

    /// @dev allows the owner of a token to remove a listing for the token
    function deleteTokenBuyItNowListing(uint256 _tokenId) external;

    /// @dev allows the owner of a token to update the price
    function updateTokenBuyItNowListingPrice(
        uint256 _tokenId,
        uint96 _listingPrice
    ) external;

    /// @dev allows the purchase of a token listed for sale
    function buyToken(uint256 _tokenId, address _recipient) external payable;

    /// @dev Get a token listing just from token ID and not worrying about current Owner
    function getTokenListing(
        uint256 _tokenId
    ) external view returns (TokenListing memory);

    /// @dev allows the contract owner to create a listing to enable sales of tokens from an edition
    function createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external;

    /// @dev allows the contract owner to remove an edition listing
    function deleteEditionBuyItNowListing(uint256 _editionId) external;

    /// @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
    function mintAndListEditionForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        string calldata _uri
    ) external returns (uint256);

    /// @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
    function setupAndListOpenEdition(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _customMintLimit
    ) external returns (uint256 _editionId);

    /// @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
    function setupAndListOpenEditionAsCollaboration(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _customMintLimit,
        address _collabFundsHandler
    ) external returns (uint256 _editionId);

    /// @dev allows the contract owner to update the price of edition tokens listed for sale
    function updateEditionBuyItNowListingPrice(
        uint256 _editionId,
        uint96 _listingPrice
    ) external;
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC721KODACreatorWithBuyItNow } from "./ERC721KODACreatorWithBuyItNow.sol";
import { UpdatableOperatorFiltererUpgradeable } from "../../operator-filter-registry/UpdatableOperatorFiltererUpgradeable.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice ERC721 KODA Creator with Embedded Primary and Secondary Buy It Now Marketplace
contract ERC721KODACreatorWithBuyItNowAndFilterRegistry is
    ERC721KODACreatorWithBuyItNow,
    UpdatableOperatorFiltererUpgradeable
{
    /// @dev Configure operator registry with init param
    function __Module_init(address _KOOperatorRegistry) internal override {
        _UpdatableOperatorFilterer_init(_KOOperatorRegistry, address(0), false);
    }

    /// @dev Required for solidity compiler due to ownable clashes
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /// @dev Override the before transfer hook so that the operator filter can be checked against the from address
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override onlyAllowedOperator(_from) {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title  UpdatableOperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFiltererUpgradeable is Initializable {

    error OperatorNotAllowed(address operator);
    error OnlyOwner();

    IOperatorFilterRegistry public operatorFilterRegistry;

    /**
     * @notice Initialise the operator filterer
     * @param _registry address of operator filter registry
     * @param subscriptionOrRegistrantToCopy address of subscription or registrant to copy
     * @param subscribe boolean if to subscribe
     */
    function _UpdatableOperatorFilterer_init(
        address _registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        operatorFilterRegistry = IOperatorFilterRegistry(_registry);

        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        _performFilterRegistryRegistrationOperations(subscriptionOrRegistrantToCopy, subscribe);
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(
        address newRegistry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) public virtual {
        if (msg.sender != owner()) revert OnlyOwner();
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        _performFilterRegistryRegistrationOperations(subscriptionOrRegistrantToCopy, subscribe);
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);

    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            address(registry) != address(0) && address(registry).code.length > 0
        ) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /// @dev Optionally perform additional registration operations after updating the operator filter registry
    function _performFilterRegistryRegistrationOperations(address subscriptionOrRegistrantToCopy, bool subscribe) internal {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external view returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(
        address registrant,
        address subscription
    ) external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function unregister(address addr) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(
        address registrant,
        address registrantToSubscribe
    ) external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(
        address registrant
    ) external returns (address[] memory);

    function subscriberAt(
        address registrant,
        uint256 index
    ) external returns (address);

    function copyEntriesOf(
        address registrant,
        address registrantToCopy
    ) external;

    function isOperatorFiltered(
        address registrant,
        address operator
    ) external returns (bool);

    function isCodeHashOfFiltered(
        address registrant,
        address operatorWithCode
    ) external returns (bool);

    function isCodeHashFiltered(
        address registrant,
        bytes32 codeHash
    ) external returns (bool);

    function filteredOperators(
        address addr
    ) external returns (address[] memory);

    function filteredCodeHashes(
        address addr
    ) external returns (bytes32[] memory);

    function filteredOperatorAt(
        address registrant,
        uint256 index
    ) external returns (address);

    function filteredCodeHashAt(
        address registrant,
        uint256 index
    ) external returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ICollabFundsHandler} from "../../handlers/ICollabFundsHandler.sol";

abstract contract CollabFundsHandlerBase is
    ICollabFundsHandler,
    ReentrancyGuardUpgradeable
{
    /// @notice in line with EIP-2981 format - precision 100.00000%
    uint256 internal constant modulo = 100_00000;

    address[] public recipients;
    uint256[] public splits;

    /**
     * @notice Using a minimal proxy contract pattern initialises the contract and sets delegation
     * @dev initialises the FundsReceiver (see https://eips.ethereum.org/EIPS/eip-1167)
     */
    function init(
        address[] calldata _recipients,
        uint256[] calldata _splits
    ) external virtual override initializer {
        require(
            _recipients.length > 0 && _recipients.length <= 4,
            "Max 4 recipients"
        );
        require(
            _recipients.length == _splits.length,
            "Inconsisent array lengths"
        );

        // Validate splits are correct
        uint256 total;
        for (uint256 i; i < _splits.length; ++i) {
            total += _splits[i];
        }
        require(total == modulo, "Invalid share total");

        recipients = _recipients;
        splits = _splits;

        __ReentrancyGuard_init();
    }

    /// get the number of recipients this funds handler is configured for
    function totalRecipients() public view virtual override returns (uint256) {
        return recipients.length;
    }

    /// get the recipient and split at the given index of the shares list
    function shareAtIndex(
        uint256 _index
    ) public view override returns (address recipient, uint256 split) {
        recipient = recipients[_index];
        split = splits[_index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollabFundsHandler {
    function init(
        address[] calldata _recipients,
        uint256[] calldata _splits
    ) external;

    function totalRecipients() external view returns (uint256);

    function shareAtIndex(
        uint256 index
    ) external view returns (address _recipient, uint256 _split);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ICollabFundsHandler} from "../handlers/ICollabFundsHandler.sol";
import {IERC721KODACreatorFactory} from "./interfaces/IERC721KODACreatorFactory.sol";
import {IKOAccessControlsLookup} from "../interfaces/IKOAccessControlsLookup.sol";

import {ERC721KODACreator} from "./ERC721KODACreator.sol";
import {KODASettings} from "../KODASettings.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
/// @notice Smart contract that facilitates the deployment of self sovereign ERC721 tokens
contract ERC721KODACreatorFactory is
    UUPSUpgradeable,
    PausableUpgradeable,
    IERC721KODACreatorFactory
{
    /// @notice Address of the access controls contract that track legitimate artists within the platform
    IKOAccessControlsLookup public accessControls;

    /// @notice global primary and secondary sale platform settings
    KODASettings public platformSettings;

    /// @notice Name of contract that will be deployed as the self sovereign unless otherwise specified
    string public defaultSelfSovereignContractName;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(string => address) public contractImplementations;

    /// @notice Address of the cloneable self sovereign contract based on the string identifier
    mapping(address => string) public implementationIdentifiers;

    /// @notice Address of the cloneable fund handler contract
    address public receiverImplementation;

    /// @notice Funds handler ID and the smart contract address deployed to handle it
    mapping(bytes32 => address) public deployedHandler;

    /// @notice A simple on chain pointer to contracts which have been flagged
    mapping(address => bool) public flaggedContracts;

    /// @notice Address of the KO Operator Registry
    address public KOOperatorRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings,
        address _KOOperatorRegistry
    ) external initializer {
        if (_erc721Implementation == address(0)) revert ZeroAddress();
        if (_receiverImplementation == address(0)) revert ZeroAddress();
        if (bytes(_erc721ImplementationName).length == 0) revert EmptyString();

        accessControls = _accessControls;
        receiverImplementation = _receiverImplementation;
        KOOperatorRegistry = _KOOperatorRegistry;

        // when initialising the factory, configure the default self sovereign implementation that will be deployed
        // other self sovereign contracts can be configured and labelled offering the ability to deploy them by supplying the label on deploy
        contractImplementations[
            _erc721ImplementationName
        ] = _erc721Implementation;

        implementationIdentifiers[
            _erc721Implementation
        ] = _erc721ImplementationName;

        defaultSelfSovereignContractName = _erc721ImplementationName;

        platformSettings = _settings;

        __Pausable_init();
        __UUPSUpgradeable_init();

        emit ContractDeployed();
    }

    ///////////////
    /// External  /
    ///////////////

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry
        );
    }

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        address _fundsHandler,
        bytes32[] calldata _artistProof
    ) external whenNotPaused {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (
            !accessControls.isVerifiedArtist(
                _artistIndex,
                msg.sender,
                _artistProof
            )
        ) revert OnlyVerifiedArtist();
        _deploySelfSovereignERC721(
            msg.sender,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry
        );
    }

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external whenNotPaused returns (address) {
        return
            _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
    }

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                contractImplementations[_nftIdentifier],
                _computeSalt(_artist, _name, _symbol),
                address(this)
            );
    }

    /// @notice The unique handler ID for a given list of recipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_recipients, _splitAmounts));
    }

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address) {
        bytes32 id = getHandlerId(_recipients, _splitAmounts);
        return deployedHandler[id];
    }

    ///////////////
    /// Admin     /
    ///////////////

    /// @dev Only authorize upgrade if user has admin role
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    function flagBannedContract(address _contract, bool _banned) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        flaggedContracts[_contract] = _banned;
        emit CreatorContractBanned(_contract, _banned);
    }

    /// @notice Disable certain actions
    function pause() external whenNotPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _pause();
    }

    /// @notice Enable all paused actions
    function unpause() external whenPaused {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _unpause();
    }

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        accessControls = _access;
    }

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_receiver == address(0)) revert ZeroAddress();
        receiverImplementation = _receiver;
    }

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_newSettings == address(0)) revert ZeroAddress();
        platformSettings = KODASettings(_newSettings);
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external {
        // check artist is legitimate or allow KO to deploy on behalf of a user
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        address fundsHandler = _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
                _recipients,
                _splitAmounts
            );
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry
        );
    }

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        _deploySelfSovereignERC721(
            _artist,
            _deploymentParams.name,
            _deploymentParams.symbol,
            _fundsHandler,
            _deploymentParams.secondaryRoyaltyPercentage,
            _deploymentParams.contractIdentifier,
            _deploymentParams.filterRegistry
        );
    }

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();

        if (contractImplementations[_identifier] != address(0))
            revert DuplicateIdentifier();
        if (bytes(implementationIdentifiers[_implementation]).length != 0)
            revert DuplicateImplementation();

        contractImplementations[_identifier] = _implementation;
        implementationIdentifiers[_implementation] = _identifier;

        emit NewImplementationAdded(_identifier);
    }

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        defaultSelfSovereignContractName = _default;
        emit DefaultImplementationUpdated(_default);
    }

    ///////////////
    /// Internal  /
    ///////////////

    /// @dev Deploy a fund handler for a given set of recipients or splits if one has not already been deployed
    function _getOrDeployFundsHandlerForAllEditionsOfSelfSovereignToken(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) internal returns (address) {
        // Deploy a fund handler if not already deployed
        bytes32 handlerId = getHandlerId(_recipients, _splitAmounts);

        address handler = deployedHandler[handlerId];
        if (handler == address(0)) {
            address receiverClone = Clones.clone(receiverImplementation);
            ICollabFundsHandler(receiverClone).init(_recipients, _splitAmounts);

            deployedHandler[handlerId] = receiverClone;

            emit FundsHandlerDeployed(receiverClone);

            return receiverClone;
        }

        return handler;
    }

    /// @dev Business logic for deploying a cloneable ERC721
    function _deploySelfSovereignERC721(
        address _artist,
        string calldata _name,
        string calldata _symbol,
        address _fundsHandler,
        uint256 _secondaryRoyaltyPercentage,
        string calldata _implementationName,
        address _filterRegistry
    ) internal {
        // Deploy the NFT
        address erc721Clone = Clones.cloneDeterministic(
            contractImplementations[_implementationName],
            _computeSalt(_artist, _name, _symbol)
        );

        ERC721KODACreator(erc721Clone).initialize(
            _artist,
            _name,
            _symbol,
            _fundsHandler,
            platformSettings,
            _secondaryRoyaltyPercentage,
            _filterRegistry
        );

        emit SelfSovereignERC721Deployed(
            msg.sender,
            _artist,
            erc721Clone,
            contractImplementations[_implementationName],
            _fundsHandler,
            _filterRegistry
        );
    }

    /// @dev Compute a deployment salt based on an address and NFT metadata
    function _computeSalt(
        address _sender,
        string calldata _name,
        string calldata _symbol
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _name, _symbol));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "../../interfaces/IKOAccessControlsLookup.sol";
import {KODASettings} from "../../KODASettings.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreatorFactory {
    error DuplicateIdentifier();
    error DuplicateImplementation();
    error EmptyString();
    error OnlyAdmin();
    error OnlyVerifiedArtist();
    error ZeroAddress();

    /// @notice Emitted when the contract is deployed in order to capture initial params
    event ContractDeployed();

    /// @notice Emitted every time a self sovereign ERC721 contract is deployed
    event SelfSovereignERC721Deployed(
        address indexed deployer,
        address indexed artist,
        address indexed selfSovereignNFT,
        address implementation,
        address fundsHandler,
        address KOOperatorRegistry
    );

    /// @notice Emitted when a fund handler is deployed
    event FundsHandlerDeployed(address indexed _handler);

    /// @notice Emitted when a new deployable contract is added
    event NewImplementationAdded(string _identifier);

    /// @notice Emitted when default contract name that is deployed is updated
    event DefaultImplementationUpdated(string _identifier);

    /// @notice Emitted when a creator contract has been banned from participating in the platform marketplace
    event CreatorContractBanned(address indexed _contract, bool _banned);

    /// @notice The base deployment parameters of a self sovereign contract
    struct SelfSovereignDeployment {
        string name; // Name that will be assigned to the NFT
        string symbol; // Symbol that will be assigned to the NFT
        string contractIdentifier; // Factory identifier for the contract being deployed
        uint256 secondaryRoyaltyPercentage; // Artist specified secondary EIP2981 royalty for items sold outside platform
        address filterRegistry; // Address of a filter registry that an artist wishes to use or zero address if they want none
    }

    function initialize(
        string calldata _erc721ImplementationName,
        address _erc721Implementation,
        address _receiverImplementation,
        IKOAccessControlsLookup _accessControls,
        KODASettings _settings,
        address _KOOperatorRegistry
    ) external;

    ///////////////
    /// External  /
    ///////////////

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        bytes32[] calldata _artistProof,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external;

    /// @notice As a verified KO artist, deploy an ERC721 KODA Creator Contract but with a custom fund handler which could be the artist themselves
    function deployCreatorContractWithCustomFundsHandler(
        SelfSovereignDeployment calldata _deploymentParams,
        uint256 _artistIndex,
        address _fundsHandler,
        bytes32[] calldata _artistProof
    ) external;

    /// @notice Deploy a fund handler for overriding editions
    function deployFundsHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external returns (address);

    /// @notice Get the address of a self sovereign NFT before deployment
    function predictDeterministicAddressOfSelfSovereignNFT(
        string calldata _nftIdentifier,
        address _artist,
        string calldata _name,
        string calldata _symbol
    ) external view returns (address);

    /// @notice The unique handler ID for a given list of receipients and splits
    function getHandlerId(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external pure returns (bytes32);

    /// @notice If deployed, will return the funds handler smart contract address for a given list of recipients and splits
    function getHandler(
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external view returns (address);

    function flagBannedContract(address _contract, bool _banned) external;

    /// @notice Disable certain actions
    function pause() external;

    /// @notice Enable all paused actions
    function unpause() external;

    /// @notice Update the access controls in the event there is an error
    function updateAccessControls(IKOAccessControlsLookup _access) external;

    /// @notice Update the implementation of funds receiver used when cloning
    function updateReceiverImplementation(address _receiver) external;

    /// @notice Update the global platforms settings contract
    function updateSettingsContract(address _newSettings) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and a fund handler at the same time
    function deployCreatorContractAndFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address[] calldata _recipients,
        uint256[] calldata _splitAmounts
    ) external;

    /// @notice On behalf of an artist, the platform can deploy an ERC721 KODA Creator Contract and use a custom handler
    function deployCreatorContractWithCustomFundsHandlerOnBehalfOfArtist(
        address _artist,
        SelfSovereignDeployment calldata _deploymentParams,
        address _fundsHandler
    ) external;

    /// @notice Adds a new self sovereign implementation contract that can be cloned
    function addCreatorImplementation(
        address _implementation,
        string calldata _identifier
    ) external;

    /// @notice Sets the default smart contract that is cloned when an artist deploys a self sovereign contract
    function updateDefaultCreatorIdentifier(string calldata _default) external;
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {ERC721KODACreatorFactory} from "../ERC721/ERC721KODACreatorFactory.sol";

contract ERC721KODACreatorFactoryUpgradeTest is ERC721KODACreatorFactory {
    function sing() external pure returns (string memory) {
        return "Singing...";
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {KODASettings} from "../KODASettings.sol";

contract KODASettingsUpgradeTest is KODASettings {
    function sing() external pure returns (string memory) {
        return "Singing...";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IKOAccessControlsLookup} from "../interfaces/IKOAccessControlsLookup.sol";
import {ISelfServiceAccessControls} from "./ISelfServiceAccessControls.sol";

/// @dev Mock version of access not to be deployed on mainnet
contract KOAccessControls is AccessControl, IKOAccessControlsLookup {
    event AdminUpdateArtistAccessMerkleRoot(bytes32 _artistAccessMerkleRoot);
    event AdminUpdateArtistAccessMerkleRootIpfsHash(
        string _artistAccessMerkleRootIpfsHash
    );

    event AddedArtistProxy(address _artist, address _proxy);

    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    ISelfServiceAccessControls public legacyMintingAccess;

    // A publicly available root merkle proof
    bytes32 public artistAccessMerkleRoot;

    // A publicly hosted ipfs payload holding the merkle proofs
    string public artistAccessMerkleRootIpfsHash;

    /// Allow an artist to set a single account to act on their behalf
    mapping(address => address) public artistProxy;

    constructor(ISelfServiceAccessControls _legacyMintingAccess) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        legacyMintingAccess = _legacyMintingAccess;
    }

    //////////////////
    // Merkle Magic //
    //////////////////

    function isVerifiedArtist(
        uint256 _index,
        address _account,
        bytes32[] calldata _merkleProof
    ) public view override returns (bool) {
        // assume balance of 1 for enabled artists
        bytes32 node = keccak256(
            abi.encodePacked(_index, _account, uint256(1))
        );
        return MerkleProof.verify(_merkleProof, artistAccessMerkleRoot, node);
    }

    /////////////
    // Lookups //
    /////////////

    function hasAdminRole(
        address _address
    ) external view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    function updateArtistMerkleRoot(bytes32 _artistAccessMerkleRoot) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender must be an admin"
        );
        artistAccessMerkleRoot = _artistAccessMerkleRoot;
        emit AdminUpdateArtistAccessMerkleRoot(_artistAccessMerkleRoot);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISelfServiceAccessControls {
    function isEnabledForAccount(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

pragma solidity 0.8.17;

import {ITokenUriResolver} from "../interfaces/ITokenUriResolver.sol";

contract TokenUriTestResolver is ITokenUriResolver {
    function tokenURI(
        uint256,
        uint256
    ) external pure override returns (string memory) {
        return "override";
    }

    function isDefined(uint256, uint256) external pure override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// N:B: Mock contract for testing purposes only
contract ERC721ReceiverMock is IERC721Receiver {
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage
    }

    bytes4 private immutable _retval;
    Error private immutable _error;

    event Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );

    constructor(bytes4 retval, Error error) {
        _retval = retval;
        _error = error;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        if (_error == Error.RevertWithMessage) {
            revert("ERC721ReceiverMock: reverting");
        } else if (_error == Error.RevertWithoutMessage) {
            revert();
        }
        emit Received(operator, from, tokenId, data, gasleft());
        return _retval;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockMarketplace {
    function transferFrom(
        address nftContract,
        uint256 tokenId,
        address from,
        address to
    ) public {
        IERC721(nftContract).transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address nftContract,
        uint256 tokenId,
        address from,
        address to
    ) external {
        IERC721(nftContract).safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFromWithData(
        address nftContract,
        uint256 tokenId,
        address from,
        address to,
        bytes calldata data
    ) external {
        IERC721(nftContract).safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Drain all funds for all parties
interface ICollabFundsDrainable {
    event FundsDrained(
        uint256 _total,
        address[] _recipients,
        uint256[] _amounts,
        address indexed _erc20
    );

    function drainERC20(IERC20 _token) external;
}

// Drain your specific share of funds only
interface ICollabFundsShareDrainable is ICollabFundsDrainable {
    function drainShare() external;

    function drainShareERC20(IERC20 _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {CollabFundsHandlerBase} from "./CollabFundsHandlerBase.sol";
import {ICollabFundsDrainable} from "./ICollabFundsDrainable.sol";

/// @title Allows funds to be received and then split later on using a pull pattern, holding a balance until drained.
/// @notice Supports claiming/draining all balances at one
/// @notice Does not an individual shares
///
/// @author KnownOrigin Labs - https://knownorigin.io/
contract ClaimableFundsReceiverSelfSovereign is
    CollabFundsHandlerBase,
    ICollabFundsDrainable
{
    // accept all funds
    receive() external payable virtual {
        drain(); // push funds to recipients
    }

    /// split current contract balance among recipients
    function drain() internal nonReentrant {
        // Check that there are funds to drain
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to drain");

        uint256[] memory shares = new uint256[](recipients.length);

        // Calculate and send share for each recipient
        uint256 sumPaidOut;
        for (uint256 i = 0; i < recipients.length; i++) {
            shares[i] = (balance * splits[i]) / modulo;

            // Deal with the first recipient later (see comment below)
            if (i != 0) {
                (bool success, ) = payable(recipients[i]).call{
                    value: shares[i]
                }("");
                require(success, "Transfer failed");
            }

            sumPaidOut += shares[i];
        }

        // The first recipient is a special address as it receives any dust left over from splitting up the funds
        uint256 remainingBalance = balance - sumPaidOut;

        // Either going to be a zero or non-zero value
        (bool _success, ) = payable(recipients[0]).call{
            value: remainingBalance + shares[0]
        }("");
        require(_success, "Transfer failed");

        emit FundsDrained(balance, recipients, shares, address(0));
    }

    /// split the current token balance among recipients
    function drainERC20(IERC20 token) public override nonReentrant {
        // Check that there are funds to drain
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to drain");

        uint256[] memory shares = new uint256[](recipients.length);

        // Calculate and send share for each recipient
        uint256 sumPaidOut;
        for (uint256 i = 0; i < recipients.length; i++) {
            shares[i] = (balance * splits[i]) / modulo;

            // Deal with the first recipient later (see comment below)
            if (i != 0) {
                token.transfer(recipients[i], shares[i]);
            }

            sumPaidOut += shares[i];
        }

        // The first recipient is a special address as it receives any dust left over from splitting up the funds
        uint256 remainingBalance = balance - sumPaidOut;
        // Either going to be a zero or non-zero value
        token.transfer(recipients[0], remainingBalance + shares[0]);

        emit FundsDrained(balance, recipients, shares, address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("Mock", "ERC20") {
    constructor() {
        _mint(msg.sender, 5_000_000 ether);
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

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OperatorFilterRegistry } from "./OperatorFilterRegistry.sol";

contract OwnableOperatorFilterRegistry is OperatorFilterRegistry, Ownable {
    constructor(address _owner) {
        _transferOwnership(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OperatorFilterRegistryErrorsAndEvents} from "./OperatorFilterRegistryErrorsAndEvents.sol";

/**
 * @title  OperatorFilterRegistry
 * @notice Borrows heavily from the QQL BlacklistOperatorFilter contract:
 *         https://github.com/qql-art/contracts/blob/main/contracts/BlacklistOperatorFilter.sol
 * @notice This contracts allows tokens or token owners to register specific addresses or codeHashes that may be
 * *       restricted according to the isOperatorAllowed function.
 */
contract OperatorFilterRegistry is
    IOperatorFilterRegistry,
    OperatorFilterRegistryErrorsAndEvents
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev initialized accounts have a nonzero codehash (see https://eips.ethereum.org/EIPS/eip-1052)
    /// Note that this will also be a smart contract's codehash when making calls from its constructor.
    bytes32 constant EOA_CODEHASH = keccak256("");

    mapping(address => EnumerableSet.AddressSet) private _filteredOperators;
    mapping(address => EnumerableSet.Bytes32Set) private _filteredCodeHashes;
    mapping(address => address) private _registrations;
    mapping(address => EnumerableSet.AddressSet) private _subscribers;

    /**
     * @notice restricts method caller to the address or EIP-173 "owner()"
     */
    modifier onlyAddressOrOwner(address addr) {
        if (msg.sender != addr) {
            try Ownable(addr).owner() returns (address owner) {
                if (msg.sender != owner) {
                    revert OnlyAddressOrOwner();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotOwnable();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        _;
    }

    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            EnumerableSet.AddressSet storage filteredOperatorsRef;
            EnumerableSet.Bytes32Set storage filteredCodeHashesRef;

            filteredOperatorsRef = _filteredOperators[registration];
            filteredCodeHashesRef = _filteredCodeHashes[registration];

            if (filteredOperatorsRef.contains(operator)) {
                revert AddressFiltered(operator);
            }
            if (operator.code.length > 0) {
                bytes32 codeHash = operator.codehash;
                if (filteredCodeHashesRef.contains(codeHash)) {
                    revert CodeHashFiltered(operator, codeHash);
                }
            }
        }
        return true;
    }

    //////////////////
    // AUTH METHODS //
    //////////////////

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(
        address registrant
    ) external onlyAddressOrOwner(registrant) {
        if (_registrations[registrant] != address(0)) {
            revert AlreadyRegistered();
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
    }

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(
        address registrant
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = address(0);
        emit RegistrationUpdated(registrant, false);
    }

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(
        address registrant,
        address subscription
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        if (registrant == subscription) {
            revert CannotSubscribeToSelf();
        }
        address subscriptionRegistration = _registrations[subscription];
        if (subscriptionRegistration == address(0)) {
            revert NotRegistered(subscription);
        }
        if (subscriptionRegistration != subscription) {
            revert CannotSubscribeToRegistrantWithSubscription(subscription);
        }

        _registrations[registrant] = subscription;
        _subscribers[subscription].add(registrant);
        emit RegistrationUpdated(registrant, true);
        emit SubscriptionUpdated(registrant, subscription, true);
    }

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external onlyAddressOrOwner(registrant) {
        if (registrantToCopy == registrant) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
        _copyEntries(registrant, registrantToCopy);
    }

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet
            storage filteredOperatorsRef = _filteredOperators[registrant];

        if (!filtered) {
            bool removed = filteredOperatorsRef.remove(operator);
            if (!removed) {
                revert AddressNotFiltered(operator);
            }
        } else {
            bool added = filteredOperatorsRef.add(operator);
            if (!added) {
                revert AddressAlreadyFiltered(operator);
            }
        }
        emit OperatorUpdated(registrant, operator, filtered);
    }

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(
        address registrant,
        bytes32 codeHash,
        bool filtered
    ) external onlyAddressOrOwner(registrant) {
        if (codeHash == EOA_CODEHASH) {
            revert CannotFilterEOAs();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set
            storage filteredCodeHashesRef = _filteredCodeHashes[registrant];

        if (!filtered) {
            bool removed = filteredCodeHashesRef.remove(codeHash);
            if (!removed) {
                revert CodeHashNotFiltered(codeHash);
            }
        } else {
            bool added = filteredCodeHashesRef.add(codeHash);
            if (!added) {
                revert CodeHashAlreadyFiltered(codeHash);
            }
        }
        emit CodeHashUpdated(registrant, codeHash, filtered);
    }

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet
            storage filteredOperatorsRef = _filteredOperators[registrant];
        uint256 operatorsLength = operators.length;
        unchecked {
            if (!filtered) {
                for (uint256 i = 0; i < operatorsLength; ++i) {
                    address operator = operators[i];
                    bool removed = filteredOperatorsRef.remove(operator);
                    if (!removed) {
                        revert AddressNotFiltered(operator);
                    }
                }
            } else {
                for (uint256 i = 0; i < operatorsLength; ++i) {
                    address operator = operators[i];
                    bool added = filteredOperatorsRef.add(operator);
                    if (!added) {
                        revert AddressAlreadyFiltered(operator);
                    }
                }
            }
        }
        emit OperatorsUpdated(registrant, operators, filtered);
    }

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set
            storage filteredCodeHashesRef = _filteredCodeHashes[registrant];
        uint256 codeHashesLength = codeHashes.length;
        unchecked {
            if (!filtered) {
                for (uint256 i = 0; i < codeHashesLength; ++i) {
                    bytes32 codeHash = codeHashes[i];
                    bool removed = filteredCodeHashesRef.remove(codeHash);
                    if (!removed) {
                        revert CodeHashNotFiltered(codeHash);
                    }
                }
            } else {
                for (uint256 i = 0; i < codeHashesLength; ++i) {
                    bytes32 codeHash = codeHashes[i];
                    if (codeHash == EOA_CODEHASH) {
                        revert CannotFilterEOAs();
                    }
                    bool added = filteredCodeHashesRef.add(codeHash);
                    if (!added) {
                        revert CodeHashAlreadyFiltered(codeHash);
                    }
                }
            }
        }
        emit CodeHashesUpdated(registrant, codeHashes, filtered);
    }

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(
        address registrant,
        address newSubscription
    ) external onlyAddressOrOwner(registrant) {
        if (registrant == newSubscription) {
            revert CannotSubscribeToSelf();
        }
        if (newSubscription == address(0)) {
            revert CannotSubscribeToZeroAddress();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == newSubscription) {
            revert AlreadySubscribed(newSubscription);
        }
        address newSubscriptionRegistration = _registrations[newSubscription];
        if (newSubscriptionRegistration == address(0)) {
            revert NotRegistered(newSubscription);
        }
        if (newSubscriptionRegistration != newSubscription) {
            revert CannotSubscribeToRegistrantWithSubscription(newSubscription);
        }

        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = newSubscription;
        _subscribers[newSubscription].add(registrant);
        emit SubscriptionUpdated(registrant, newSubscription, true);
    }

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(
        address registrant,
        bool copyExistingEntries
    ) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == registrant) {
            revert NotSubscribed();
        }
        _subscribers[registration].remove(registrant);
        _registrations[registrant] = registrant;
        emit SubscriptionUpdated(registrant, registration, false);
        if (copyExistingEntries) {
            _copyEntries(registrant, registration);
        }
    }

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(
        address registrant,
        address registrantToCopy
    ) external onlyAddressOrOwner(registrant) {
        if (registrant == registrantToCopy) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _copyEntries(registrant, registrantToCopy);
    }

    /// @dev helper to copy entries from registrantToCopy to registrant and emit events
    function _copyEntries(
        address registrant,
        address registrantToCopy
    ) private {
        EnumerableSet.AddressSet
            storage filteredOperatorsRef = _filteredOperators[registrantToCopy];
        EnumerableSet.Bytes32Set
            storage filteredCodeHashesRef = _filteredCodeHashes[
                registrantToCopy
            ];
        uint256 filteredOperatorsLength = filteredOperatorsRef.length();
        uint256 filteredCodeHashesLength = filteredCodeHashesRef.length();
        unchecked {
            for (uint256 i = 0; i < filteredOperatorsLength; ++i) {
                address operator = filteredOperatorsRef.at(i);
                bool added = _filteredOperators[registrant].add(operator);
                if (added) {
                    emit OperatorUpdated(registrant, operator, true);
                }
            }
            for (uint256 i = 0; i < filteredCodeHashesLength; ++i) {
                bytes32 codehash = filteredCodeHashesRef.at(i);
                bool added = _filteredCodeHashes[registrant].add(codehash);
                if (added) {
                    emit CodeHashUpdated(registrant, codehash, true);
                }
            }
        }
    }

    //////////////////
    // VIEW METHODS //
    //////////////////

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(
        address registrant
    ) external view returns (address subscription) {
        subscription = _registrations[registrant];
        if (subscription == address(0)) {
            revert NotRegistered(registrant);
        } else if (subscription == registrant) {
            subscription = address(0);
        }
    }

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(
        address registrant
    ) external view returns (address[] memory) {
        return _subscribers[registrant].values();
    }

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(
        address registrant,
        uint256 index
    ) external view returns (address) {
        return _subscribers[registrant].at(index);
    }

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(
        address registrant,
        address operator
    ) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].contains(operator);
        }
        return _filteredOperators[registrant].contains(operator);
    }

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(
        address registrant,
        bytes32 codeHash
    ) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(
        address registrant,
        address operatorWithCode
    ) external view returns (bool) {
        bytes32 codeHash = operatorWithCode.codehash;
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address registrant) external view returns (bool) {
        return _registrations[registrant] != address(0);
    }

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(
        address registrant
    ) external view returns (address[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].values();
        }
        return _filteredOperators[registrant].values();
    }

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(
        address registrant
    ) external view returns (bytes32[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].values();
        }
        return _filteredCodeHashes[registrant].values();
    }

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(
        address registrant,
        uint256 index
    ) external view returns (address) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].at(index);
        }
        return _filteredOperators[registrant].at(index);
    }

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(
        address registrant,
        uint256 index
    ) external view returns (bytes32) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].at(index);
        }
        return _filteredCodeHashes[registrant].at(index);
    }

    /// @dev Convenience method to compute the code hash of an arbitrary contract
    function codeHashOf(address a) external view returns (bytes32) {
        return a.codehash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OperatorFilterRegistryErrorsAndEvents {
    error CannotFilterEOAs();
    error AddressAlreadyFiltered(address operator);
    error AddressNotFiltered(address operator);
    error CodeHashAlreadyFiltered(bytes32 codeHash);
    error CodeHashNotFiltered(bytes32 codeHash);
    error OnlyAddressOrOwner();
    error NotRegistered(address registrant);
    error AlreadyRegistered();
    error AlreadySubscribed(address subscription);
    error NotSubscribed();
    error CannotUpdateWhileSubscribed(address subscription);
    error CannotSubscribeToSelf();
    error CannotSubscribeToZeroAddress();
    error NotOwnable();
    error AddressFiltered(address filtered);
    error CodeHashFiltered(address account, bytes32 codeHash);
    error CannotSubscribeToRegistrantWithSubscription(address registrant);
    error CannotCopyFromSelf();

    event RegistrationUpdated(
        address indexed registrant,
        bool indexed registered
    );
    event OperatorUpdated(
        address indexed registrant,
        address indexed operator,
        bool indexed filtered
    );
    event OperatorsUpdated(
        address indexed registrant,
        address[] operators,
        bool indexed filtered
    );
    event CodeHashUpdated(
        address indexed registrant,
        bytes32 indexed codeHash,
        bool indexed filtered
    );
    event CodeHashesUpdated(
        address indexed registrant,
        bytes32[] codeHashes,
        bool indexed filtered
    );
    event SubscriptionUpdated(
        address indexed registrant,
        address indexed subscription,
        bool indexed subscribed
    );
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import { OwnableOperatorFilterRegistry } from "./OwnableOperatorFilterRegistry.sol";

contract OperatorFilterRegistryDeployer {

    event NewDeployment(address indexed newDeployment);

    function deploy(address _owner) external returns (address) {
        address newInstance = address(new OwnableOperatorFilterRegistry(_owner));

        emit NewDeployment(newInstance);

        return newInstance;
    }
}