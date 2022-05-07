// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ITokengateManifoldExtension.sol";

/**
 * @title Default implementation of the ITokengateManifoldExtension interface.
 *
 * See {ITokengateManifoldExtension} for more information and a detailed explanation on the way the
 * token URI generation works.
 *
 * @author DSENT AG, www.dsent.com
 */
contract TokengateManifoldExtension is
    ITokengateManifoldExtension,
    CreatorExtension,
    ICreatorExtensionTokenURI,
    AccessControlEnumerable
{
    using Strings for uint256;

    /**
     * @dev Role for all addresses that are authorized to mint tokens through this extension.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Variable that stores the base token URI that is used during token URI generation. The base
     * token URI is used for editions that have neither a token URI suffix nor a full token URI specified.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    string private _baseTokenURI;

    /**
     * @dev Variable that stores the default token URI prefix that is used during token URI generation.
     * The default token URI prefix is used for editions that have a token URI suffix defined.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    string private _defaultTokenURIPrefix;

    /**
     * @dev Variable that stores custom token URI suffixes for single editions or editions of a series.
     *
     * Note: Maps creator addresses => tokenIds => token URI suffixes
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    mapping(address => mapping(uint256 => string)) private _tokenURISuffixMap;

    /**
     * @dev Variable that stores full token URIs for single editions or editions of a series.
     *
     * Note: Maps creator addresses => tokenIds => full token URIs
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    mapping(address => mapping(uint256 => string)) private _fullTokenURIMap;

    /**
     * @dev Variable that stores all series created for the specified project ids.
     *
     * Note: Maps project ids => Series custom types
     */
    mapping(uint64 => Series) private _seriesMap;

    /**
     * @dev Variable that stores whether a given edition id has been minted or not. Edition ids are
     * created by bit shifting a 64-bit project id with a 32-bit edition number into a 96-bit uint.
     *
     * Note: Maps edition ids => edition minted booleans
     */
    mapping(uint96 => bool) private _mintedEditionIdMap;

    /**
     * @dev Variable that stores edition ids for all created token ids. Edition ids consist of a
     * project id and edition number and are stored by bit shifting the 64-bit project id with the
     * 32-bit edition number into a 96-bit uint.
     *
     * Note: Maps creator addresses => token ids => edition ids
     */
    mapping(address => mapping(uint256 => uint96)) private _editionIdMap;

    /**
     * @dev Note: Declaring a constructor `payable` reduces the deployed EVM bytecode by 10 opcodes.
     */
    constructor(string memory baseTokenURI, string memory defaultTokenURIPrefix)
        payable
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI;
        _defaultTokenURIPrefix = defaultTokenURIPrefix;
    }

    /**
     * @dev Check whether a given interface is supported by this extension.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CreatorExtension, IERC165, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            CreatorExtension.supportsInterface(interfaceId) ||
            interfaceId == type(ITokengateManifoldExtension).interfaceId ||
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-createSeries}.
     */
    function createSeries(
        uint64 projectId,
        uint32 editionSize,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external onlyRole(MINTER_ROLE) {
        if (projectId == 0) {
            revert ProjectIdMustBePositive(address(this));
        }
        if (editionSize <= 1) {
            revert EditionSizeMustBeGreaterThanOne(address(this));
        }
        if (_seriesMap[projectId].hasEntry) {
            revert SeriesAlreadyCreated(address(this));
        }
        if (_mintedEditionIdMap[createEditionId(projectId, 1)]) {
            revert ProjectIsMintedAsSingleEdition(address(this));
        }

        _seriesMap[projectId] = Series(
            true,
            editionSize,
            0,
            tokenURIPrefix,
            tokenURISuffix,
            addEditionToTokenURISuffix,
            tokenURIExtension
        );

        emit SeriesCreated(projectId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-setSeriesParams}.
     */
    function setSeriesParams(
        uint64 projectId,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external onlyRole(MINTER_ROLE) {
        if (!_seriesMap[projectId].hasEntry) {
            revert SeriesNotFound(address(this));
        }

        Series storage series = _seriesMap[projectId];
        series.tokenURIPrefix = tokenURIPrefix;
        series.tokenURISuffix = tokenURISuffix;
        series.addEditionToTokenURISuffix = addEditionToTokenURISuffix;
        series.tokenURIExtension = tokenURIExtension;

        emit SeriesParamsSet(projectId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getSeries}.
     */
    function getSeries(uint64 projectId) external view returns (Series memory) {
        return _seriesMap[projectId];
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeries}.
     */
    function mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string memory tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        _mintSeries(
            creator,
            recipient,
            projectId,
            editionNumber,
            isFullTokenURI,
            tokenURIData
        );
    }

    /**
     * @dev Internal function used to mint editions of a series.
     */
    function _mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string memory tokenURIData
    ) internal {
        if (recipient == address(0)) {
            revert ZeroAddressNotAllowed(address(this));
        }
        if (!_seriesMap[projectId].hasEntry) {
            revert SeriesNotFound(address(this));
        }

        if (editionNumber == 0) {
            revert EditionNumberMustBePositive(address(this));
        }

        if (editionNumber > _seriesMap[projectId].editionSize) {
            revert EditionNumberExceedsEditionSize(address(this));
        }

        uint96 editionId = createEditionId(projectId, editionNumber);
        if (_mintedEditionIdMap[editionId]) {
            revert EditionAlreadyMinted(address(this));
        }
        _mintedEditionIdMap[editionId] = true;
        _seriesMap[projectId].editionCount += 1;

        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(recipient);

        if (bytes(tokenURIData).length != 0) {
            if (isFullTokenURI) {
                _fullTokenURIMap[creator][tokenId] = tokenURIData;
            } else {
                _tokenURISuffixMap[creator][tokenId] = tokenURIData;
            }
        }

        _editionIdMap[creator][tokenId] = editionId;

        emit EditionMinted(creator, tokenId, projectId, editionNumber);
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatch1}.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions
    ) external onlyRole(MINTER_ROLE) {
        for (uint32 i = 0; i < nbEditions; ) {
            _mintSeries(
                creator,
                recipient,
                projectId,
                startEditionNumber + i,
                false,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatch1}.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        if (
            isFullTokenURIs.length != nbEditions ||
            tokenURIData.length != nbEditions
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint32 i = 0; i < nbEditions; ) {
            _mintSeries(
                creator,
                recipient,
                projectId,
                startEditionNumber + i,
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatchN}.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize || editionNumbers.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            _mintSeries(
                creator,
                recipients[i],
                projectIds[i],
                editionNumbers[i],
                false,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatchN}.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize ||
            editionNumbers.length != batchSize ||
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            _mintSeries(
                creator,
                recipients[i],
                projectIds[i],
                editionNumbers[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingle}.
     */
    function mintSingle(
        address creator,
        address recipient,
        uint64 projectId,
        bool isFullTokenURI,
        string memory tokenURIData
    ) public onlyRole(MINTER_ROLE) {
        if (recipient == address(0)) {
            revert ZeroAddressNotAllowed(address(this));
        }
        if (projectId == 0) {
            revert ProjectIdMustBePositive(address(this));
        }

        uint96 editionId = createEditionId(projectId, 1);

        if (_mintedEditionIdMap[editionId]) {
            revert EditionAlreadyMinted(address(this));
        }
        if (_seriesMap[projectId].hasEntry) {
            revert ProjectIsMintedAsSeries(address(this));
        }

        _mintedEditionIdMap[editionId] = true;

        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(recipient);

        if (bytes(tokenURIData).length != 0) {
            if (isFullTokenURI) {
                _fullTokenURIMap[creator][tokenId] = tokenURIData;
            } else {
                _tokenURISuffixMap[creator][tokenId] = tokenURIData;
            }
        }

        _editionIdMap[creator][tokenId] = editionId;

        emit EditionMinted(creator, tokenId, projectId, 1);
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingleBatch}.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (projectIds.length != batchSize) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            mintSingle(creator, recipients[i], projectIds[i], false, "");

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingleBatch}.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize ||
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            mintSingle(
                creator,
                recipients[i],
                projectIds[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata baseTokenURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getBaseTokenURI}.
     */
    function getBaseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ITokengateManifoldExtension-setDefaultTokenURIPrefix}.
     */
    function setDefaultTokenURIPrefix(string calldata defaultTokenURIPrefix_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _defaultTokenURIPrefix = defaultTokenURIPrefix_;
        emit DefaultTokenURIPrefixSet(_defaultTokenURIPrefix);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getDefaultTokenURIPrefix}.
     */
    function getDefaultTokenURIPrefix() external view returns (string memory) {
        return _defaultTokenURIPrefix;
    }

    /**
     * @dev See {ITokengateManifoldExtension-setTokenURIData}.
     */
    function setTokenURIData(
        address creator,
        uint256 tokenId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) public onlyRole(MINTER_ROLE) {
        if (_editionIdMap[creator][tokenId] == 0) {
            revert TokenNotFound(address(this));
        }
        if (isFullTokenURI) {
            _fullTokenURIMap[creator][tokenId] = tokenURIData;
        } else {
            _tokenURISuffixMap[creator][tokenId] = tokenURIData;
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-setTokenURIDataBatch}.
     */
    function setTokenURIDataBatch(
        address creator,
        uint256[] calldata tokenIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = tokenIds.length;
        if (
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            setTokenURIData(
                creator,
                tokenIds[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-getTokenURISuffix}.
     */
    function getTokenURISuffix(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _tokenURISuffixMap[creator][tokenId];
    }

    /**
     * @dev See {ITokengateManifoldExtension-getFullTokenURI}.
     */
    function getFullTokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _fullTokenURIMap[creator][tokenId];
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information.
     */
    function tokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory fullTokenURI = _fullTokenURIMap[creator][tokenId];
        if (bytes(fullTokenURI).length != 0) {
            return fullTokenURI;
        }

        (uint64 projectId, uint32 editionNumber) = splitEditionId(
            _editionIdMap[creator][tokenId]
        );

        Series memory series = _seriesMap[projectId];
        if (series.hasEntry) {
            return
                getSeriesTokenURI(creator, tokenId, projectId, editionNumber);
        }

        string memory tokenURISuffix = _tokenURISuffixMap[creator][tokenId];
        if (bytes(tokenURISuffix).length != 0) {
            return
                string(
                    abi.encodePacked(_defaultTokenURIPrefix, tokenURISuffix)
                );
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    toString(creator),
                    "-",
                    tokenId.toString()
                )
            );
    }

    /**
     * @dev Internal function used to generate the tokenURI for an edition of a series.
     */
    function getSeriesTokenURI(
        address creator,
        uint256 tokenId,
        uint64 projectId,
        uint32 editionNumber
    ) internal view returns (string memory) {
        string memory suffix = _tokenURISuffixMap[creator][tokenId];
        Series memory series = _seriesMap[projectId];

        if (
            bytes(series.tokenURISuffix).length == 0 &&
            bytes(suffix).length == 0
        ) {
            return
                string(
                    abi.encodePacked(
                        _baseTokenURI,
                        toString(creator),
                        "-",
                        tokenId.toString()
                    )
                );
        }

        string memory tokenURIPrefix = getSeriesTokenURIPrefix(projectId);

        if (bytes(suffix).length != 0) {
            return string(abi.encodePacked(tokenURIPrefix, suffix));
        }

        if (series.addEditionToTokenURISuffix) {
            if (bytes(series.tokenURIExtension).length != 0) {
                return
                    string(
                        abi.encodePacked(
                            tokenURIPrefix,
                            series.tokenURISuffix,
                            uint256(editionNumber).toString(),
                            series.tokenURIExtension
                        )
                    );
            }

            return
                string(
                    abi.encodePacked(
                        tokenURIPrefix,
                        series.tokenURISuffix,
                        uint256(editionNumber).toString()
                    )
                );
        }

        return string(abi.encodePacked(tokenURIPrefix, series.tokenURISuffix));
    }

    /**
     * @dev Internal function used to determine the token URI prefix to use for an edition of a series.
     */
    function getSeriesTokenURIPrefix(uint64 projectId)
        internal
        view
        returns (string memory)
    {
        Series memory series = _seriesMap[projectId];

        if (bytes(series.tokenURIPrefix).length != 0) {
            return series.tokenURIPrefix;
        }

        return _defaultTokenURIPrefix;
    }

    /**
     * @dev See {ITokengateManifoldExtension-getTokenInfo}.
     */
    function getTokenInfo(address creator, uint256 tokenId)
        external
        view
        returns (uint64 projectId, uint32 editionNumber)
    {
        uint96 editionId = _editionIdMap[creator][tokenId];
        if (editionId == 0) {
            revert TokenNotFound(address(this));
        }
        (projectId, editionNumber) = splitEditionId(
            _editionIdMap[creator][tokenId]
        );
    }

    /**
     * @dev See {ITokengateManifoldExtension-isSeries}.
     */
    function isSeries(uint64 projectId) external view returns (bool) {
        return _seriesMap[projectId].hasEntry;
    }

    /**
     * @dev See {ITokengateManifoldExtension-isMinted}.
     */
    function isMinted(uint64 projectId, uint32 editionNumber)
        external
        view
        returns (bool)
    {
        return _mintedEditionIdMap[createEditionId(projectId, editionNumber)];
    }

    /**
     * @dev See {ITokengateManifoldExtension-createEditionId}.
     */
    function createEditionId(uint64 projectId, uint32 editionNumber)
        public
        pure
        returns (uint96)
    {
        uint96 editionId = projectId;
        editionId = editionId << 32;
        editionId = editionId + editionNumber;
        return editionId;
    }

    /**
     * @dev See {ITokengateManifoldExtension-splitEditionId}.
     */
    function splitEditionId(uint96 editionId)
        public
        pure
        returns (uint64 projectId, uint32 editionNumber)
    {
        projectId = uint64(editionId >> 32);
        editionNumber = uint32(editionId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getRoleMembers}.
     */
    function getRoleMembers(bytes32 role)
        public
        view
        returns (address[] memory)
    {
        uint256 roleCount = getRoleMemberCount(role);
        address[] memory members = new address[](roleCount);
        for (uint256 i = 0; i < roleCount; ) {
            members[i] = getRoleMember(role, i);

            unchecked {
                ++i;
            }
        }
        return members;
    }

    /**
     * @dev Convert an address to a string.
     */
    function toString(address addr) public pure returns (string memory) {
        uint256 data = uint256(uint160(addr));
        return data.toHexString();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension is ERC165 {

    /**
     * @dev Legacy extension interface identifiers
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */
    bytes4 constant internal LEGACY_EXTENSION_INTERFACE = 0x7005caad;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == LEGACY_EXTENSION_INTERFACE
            || super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title An extension for Manifold Creator contracts that allows the various NFT marketplaces run by
 * DSENT AG to mint tokens on behalf of a creator. The extension ensures that only a limited number of
 * editions can be minted for any given project. A project in the context of this extension serves as
 * a general term for a wide range of collectibles such as artworks, PFPs, club memberships, etc.
 * Projects can either be minted as single editions or editions of a series with a predefined maximum size.
 *
 * @author DSENT AG, www.dsent.com
 *
 * Token URI Generation:
 * ---------------------
 * The logic used to generate a URI for a specified token id uses one of three approaches
 * based on the provided token URI data. Token URI data is always specified using `isFullTokenURI` and
 * `tokenURIData` parameters. If `isFullTokenURI == true` then `tokenURIData` will be interpreted as a
 * complete token URI and no further concatenation logic will be applied. For `isFullTokenURI == false`
 * the `tokenURIData` is used as a URI suffix and is concatenated with a URI prefix to form a complete
 * token URI.
 *
 * Token URI data can either be specified during minting or afterwards using either `setTokenURIData()`
 * or its batch variant `setTokenURIDataBatch()`.
 *
 * The three approaches for URI generation work as follows:
 *
 * 1. If no specific token URI data is specified, the base token URI is concatenated with the creator
 * address and the token id to form a complete URI.
 *
 * 2. If a token URI suffix is specified for a given token, then that suffix gets concatenated with
 * a token URI prefix to form a complete URI.
 *
 * For all single editions the token URI prefix is read from the default token URI prefix variable.
 * Editions of a series on the other hand can use an optional override of the default prefix that
 * can be specified during `createSeries()` or `setSeriesParams()` calls.
 *
 * A token URI suffix can be defined directly on the token level using the URI data parameters
 * of the minting or `setTokenURIData()`/`setTokenURIDataBatch()` calls. Alternatively, it is also possible to
 * to define a suffix that applies to all editions of a series. Such a suffix can be specified during
 * `createSeries()` or `setSeriesParams()` calls. In the case of a series it is further possible to set
 * `addEditionToTokenURISuffix = true`, which will cause the concatenation logic to append the
 * edition number to the specified suffix. If necessary, an optional `tokenURIExtension` can be
 * specified, in order to append an additional extension after the edition number. This is useful if
 * an endpoint has no proper support for Content-Type headers.
 *
 * It is important to understand that a suffix defined on the token level will always take precedence
 * over one defined on a series level.
 *
 * 3. If a full token URI is specified for a given token, then that full URI takes precedence over
 * everything else. It will override a suffix that might be specified for that token.
 *
 * A full token URI must be defined directly on the token level using the URI data parameters
 * of the minting or `setTokenURIData()`/`setTokenURIDataBatch()` calls.
 */
interface ITokengateManifoldExtension is IERC165 {
    /**
     * @dev Event that is emitted when a new single edition or an edition of a series is minted.
     */
    event EditionMinted(
        address indexed creator,
        uint256 indexed tokenId,
        uint64 indexed projectId,
        uint32 editionNumber
    );

    /**
     * @dev Event that is emitted when a new series with a predefined edition size is created.
     */
    event SeriesCreated(uint64 indexed projectId);

    /**
     * @dev Event that is emitted when the parameters of a series are changed that drive the
     * token URI generation of the editions belonging to that series.
     */
    event SeriesParamsSet(uint64 indexed projectId);

    /**
     * @dev Event that is emitted when the base token URI is changed that is used during tokenURI
     * generation. The base token URI is used for editions that have neither a token URI suffix nor
     * a full token URI specified.
     */
    event BaseTokenURISet(string baseTokenURI);

    /**
     * @dev Event that is emitted when the default token URI prefix is changed that is used during
     * token URI generation. The default token URI prefix is used for editions that have a token URI suffix
     * defined.
     */
    event DefaultTokenURIPrefixSet(string defaultTokenURIPrefix);

    /**
     * @dev Error that occurs when specifying a project id of zero.
     */
    error ProjectIdMustBePositive(address emitter);

    /**
     * @dev Error that occurs when creating a series that does not consist of at least two editions.
     */
    error EditionSizeMustBeGreaterThanOne(address emitter);

    /**
     * @dev Error that occurs when minting a token of a series with an edition number of zero.
     */
    error EditionNumberMustBePositive(address emitter);

    /**
     * @dev Error that occurs when minting a token of a series with an edition number that is larger
     * than the maximum allowed size for that series.
     */
    error EditionNumberExceedsEditionSize(address emitter);

    /**
     * @dev Error that occurs when creating a series with a project id that belongs to an already
     * existing series.
     */
    error SeriesAlreadyCreated(address emitter);

    /**
     * @dev Error that occurs when creating a series for a project id that was already used to mint
     * a single edition.
     */
    error ProjectIsMintedAsSingleEdition(address emitter);

    /**
     * @dev Error that occurs when minting an edition for a project id and edition number
     * that is already used by another single edition or an edition of a series.
     */
    error EditionAlreadyMinted(address emitter);

    /**
     * @dev Error that occurs when minting a single edition for a project id that was already used
     * to create a series.
     */
    error ProjectIsMintedAsSeries(address emitter);

    /**
     * @dev Error that occurs when specifying a project id that does not belong to any of the
     * created series.
     */
    error SeriesNotFound(address emitter);

    /**
     * @dev Error that occurs when specifying the 0x0 address.
     */
    error ZeroAddressNotAllowed(address emitter);

    /**
     * @dev Error that occurs when the length of the parameter arrays used in a batch operation
     * do not match.
     */
    error ArrayLengthMismatch(address emitter);

    /**
     * @dev Error that occurs when specifying a token id that does not exist.
     */
    error TokenNotFound(address emitter);

    /**
     * @dev Custom type that is used to represent a series of limited edition tokens belonging to
     * a certain project. Series are always referenced by the project id that they belong to.
     */
    struct Series {
        /**
         * @dev Variable that stores whether a series was created for a given project id.
         */
        bool hasEntry;
        /**
         * @dev Variable that stores the maximum number of editions that can be minted for the series.
         */
        uint32 editionSize;
        /**
         * @dev Variable that stores the number of editions that have been minted for the series.
         */
        uint32 editionCount;
        /**
         * @dev Variable that stores an optional override for the default token URI prefix that is used
         * for all editions of the series.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURIPrefix;
        /**
         * @dev Variable that stores an optional token URI suffix that is used for all editions of
         * the series.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURISuffix;
        /**
         * @dev Variable that controls whether the edition number is to be added to the token URI suffix
         * during token URI generation or not.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        bool addEditionToTokenURISuffix;
        /**
         * @dev Variable that stores an optional extension to add to the edition number during
         * token URI generation. Setting this value only makes sense when `addEditionToTokenURISuffix == true`.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURIExtension;
    }

    /**
     * @dev Create a new series of limited edition tokens belonging to a certain project.
     */
    function createSeries(
        uint64 projectId,
        uint32 editionSize,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external;

    /**
     * @dev Set the parameters of a series that drive the token URI generation of its editions.
     */
    function setSeriesParams(
        uint64 projectId,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external;

    /**
     * @dev Get the custom type that stores all the state variables for the specified series.
     */
    function getSeries(uint64 projectId) external view returns (Series memory);

    /**
     * @dev Mint a new edition for the series specified by the project id.
     *
     * Note: If no custom token URI data is required, use `isFullTokenURI = false` and `tokenURIData = ''`
     */
    function mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new editions to a single recipient for the series specified by the project id.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions
    ) external;

    /**
     * @dev Batch mint new editions to a single recipient for the series specified by the project id.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new editions to multiple recipients for the series specified by the project id.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers
    ) external;

    /**
     * @dev Batch mint new editions to multiple recipients for the series specified by the project id.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Mint a new single edition for the specified project id.
     *
     * Note: If no custom token URI data is required, use `isFullTokenURI = false` and `tokenURIData = ''`
     */
    function mintSingle(
        address creator,
        address recipient,
        uint64 projectId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new single editions to multiple recipients for the specified project ids.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds
    ) external;

    /**
     * @dev Batch mint new single editions to multiple recipients for the specified project ids.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Set the base token URI that is used during token URI generation. The base token URI is
     * used for editions that have neither a token URI suffix nor a full token URI specified.
     */
    function setBaseTokenURI(string calldata baseTokenURI) external;

    /**
     * @dev Get the base token URI that is used during token URI generation. The base token URI is
     * used for editions that have neither a token URI suffix nor a full token URI specified.
     */
    function getBaseTokenURI() external view returns (string memory);

    /**
     * @dev Set the default token URI prefix that is used during token URI generation. The default
     * token URI prefix is used for editions that have a token URI suffix defined.
     */
    function setDefaultTokenURIPrefix(string calldata defaultTokenURIPrefix)
        external;

    /**
     * @dev Get the default token URI prefix that is used during token URI generation. The default
     * token URI prefix is used for editions that have a token URI suffix defined.
     */
    function getDefaultTokenURIPrefix() external view returns (string memory);

    /**
     * @dev Set either a full token URI (if `isFullTokenURI == true`) or a token URI suffix (if `isFullTokenURI == false`)
     * for the specified token id.
     *
     * Note: Specifying a full token URI always takes precedence over any other token URI generation
     * logic. If a currently active full token URI is to be replaced by a token URI suffix, make sure
     * to reset the full token URI value before by specifying an empty string '' in `tokenURIData`.
     *
     * Refer to the 'Token URI Generation' section above for more information.
     */
    function setTokenURIData(
        address creator,
        uint256 tokenId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch set either full token URIs (if `isFullTokenURI == true`) or token URI suffixes (if `isFullTokenURI == false`)
     * for the specified token ids.
     *
     * Note: Specifying a full token URI always takes precedence over any other token URI generation
     * logic. If a currently active full token URI is to be replaced by a token URI suffix, make sure
     * to reset the full token URI value before by specifying an empty string '' in `tokenURIData`.
     *
     * Refer to the 'Token URI Generation' section above for more information.
     */
    function setTokenURIDataBatch(
        address creator,
        uint256[] calldata tokenIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Get the token URI suffix for the specified token id if one has been set.
     */
    function getTokenURISuffix(address creator, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Get the full token URI for the specified token id if one has been set.
     */
    function getFullTokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Get the token info consisting of the project id and edition number for the specified token id.
     */
    function getTokenInfo(address creator, uint256 tokenId)
        external
        view
        returns (uint64 projectId, uint32 editionNumber);

    /**
     * @dev Check whether a series has been created for the specified project id.
     */
    function isSeries(uint64 projectId) external view returns (bool);

    /**
     * @dev Check whether an edition has been minted for the specified project id and edition number.
     */
    function isMinted(uint64 projectId, uint32 editionNumber)
        external
        view
        returns (bool);

    /**
     * @dev Create an edition id by bit shifting a 64-bit project id with a 32-bit edition number into a 96-bit uint.
     */
    function createEditionId(uint64 projectId, uint32 editionNumber)
        external
        pure
        returns (uint96);

    /**
     * @dev Split an edition id by bit shifting the 96-bit uint into a 64-bit project id and a 32-bit edition number.
     */
    function splitEditionId(uint96 editionId)
        external
        pure
        returns (uint64 projectId, uint32 editionNumber);

    /**
     * @dev Get all addresses that are granted the specified role.
     */
    function getRoleMembers(bytes32 role)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
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