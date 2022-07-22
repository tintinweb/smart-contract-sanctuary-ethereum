// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BoundLayerable} from '../BoundLayerable.sol';
import {RandomTraitsImpl} from '../traits/RandomTraitsImpl.sol';
import {IncorrectPayment} from '../interface/Errors.sol';
import {ERC721A} from '../token/ERC721A.sol';
import {ImageLayerable} from '../metadata/ImageLayerable.sol';

contract TestnetToken is BoundLayerable, RandomTraitsImpl {
    uint256 public constant MINT_PRICE = 0 ether;

    constructor()
        BoundLayerable(
            'test',
            'TEST',
            0x6168499c0cFfCaCD319c818142124B7A15E857ab,
            1000,
            7,
            8632,
            address(0)
        )
    {
        // metadataContract = new ImageLayerable('default', msg.sender);
    }

    modifier includesCorrectPayment(uint256 numSets) {
        if (msg.value != numSets * MINT_PRICE) {
            revert IncorrectPayment();
        }
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    function mintSet() public payable includesCorrectPayment(1) {
        _setPlaceholderBinding(_nextTokenId());
        super._mint(msg.sender, NUM_TOKENS_PER_SET);
    }

    // todo: restrict numminted
    function mintSets(uint256 numSets)
        public
        payable
        includesCorrectPayment(numSets)
    {
        super._mint(msg.sender, NUM_TOKENS_PER_SET * numSets);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {PackedByteUtility} from './lib/PackedByteUtility.sol';
import {BitMapUtility} from './lib/BitMapUtility.sol';
import {LayerVariation} from './interface/Structs.sol';
import {ILayerable} from './metadata/ILayerable.sol';
import {Layerable} from './metadata/Layerable.sol';

import {RandomTraits} from './traits/RandomTraits.sol';
import {ERC721A} from './token/ERC721A.sol';

import './interface/Errors.sol';
import {NOT_0TH_BITMASK, DUPLICATE_ACTIVE_LAYERS_SIGNATURE, LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE} from './interface/Constants.sol';
import {BoundLayerableEvents} from './interface/Events.sol';
import {LayerType} from './interface/Enums.sol';

abstract contract BoundLayerable is RandomTraits, BoundLayerableEvents {
    using BitMapUtility for uint256;

    // mapping from tokenID to a bitmap of bound layers, where each bit is a boolean indicating the layerId at its
    // position has been bound. Layers are bound to bases by burning them with one of the burnAndBind methods.
    // LayerID zero is not valid, but is set at mint to reduce gas cost when binding the first layers, when it is unset
    mapping(uint256 => uint256) internal _tokenIdToBoundLayers;
    // mapping from tokenID to packed array of (nonzero) bytes indicating the ordered layerIds that are active for the token
    // only layerIds bound to the base tokenId can be set as active, and duplicates are not allowed.
    mapping(uint256 => uint256) internal _tokenIdToPackedActiveLayers;

    ILayerable public metadataContract;

    modifier canMint(uint256 numSets) {
        // get number of tokens to be minted, add next token id, compare to max token id (MAX_NUM_SETS * NUM_TOKENS_PER_SET)
        if (
            numSets * uint256(NUM_TOKENS_PER_SET) + _nextTokenId() >
            MAX_TOKEN_ID
        ) {
            revert MaxSupply();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId,
        address _metadataContractAddress
    )
        RandomTraits(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId
        )
    {
        metadataContract = ILayerable(_metadataContractAddress);
    }

    /////////////
    // GETTERS //
    /////////////

    /// @notice get the layerIds currently bound to a tokenId
    function getBoundLayers(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return BitMapUtility.unpackBitMap(getBoundLayerBitMap(tokenId));
    }

    /// @notice get the layerIds currently bound to a tokenId as a bit map
    function getBoundLayerBitMap(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdToBoundLayers[tokenId] & NOT_0TH_BITMASK;
    }

    /// @notice get the layerIds currently active on a tokenId
    function getActiveLayers(uint256 tokenId)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 activePackedLayers = _tokenIdToPackedActiveLayers[tokenId];
        return PackedByteUtility.unpackByteArray(activePackedLayers);
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return
            metadataContract.getTokenURI(
                getLayerId(tokenId),
                getBoundLayerBitMap(tokenId),
                getActiveLayers(tokenId),
                getRandomnessForTokenIdFromSeed(tokenId, packedBatchRandomness)
            );
    }

    /////////////
    // SETTERS //
    /////////////

    /// @notice set the address of the metadata contract. OnlyOwner
    /// @param _metadataContract the address of the metadata contract
    function setMetadataContract(ILayerable _metadataContract)
        external
        onlyOwner
    {
        _setMetadataContract(_metadataContract);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindSingleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256 layerTokenId,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindSingle(baseTokenId, layerTokenId);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindMultipleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * emits LayersBoundToToken
     */
    function burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        public
        virtual
    {
        _burnAndBindSingle(baseTokenId, layerTokenId);
    }

    /**
     * @notice Bind layer tokens to a base token and burn the layer tokens. User must own all tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * emits LayersBoundToToken
     */
    function burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) public virtual {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
    }

    /**
     * @notice Set the active layer IDs for a base token. Layers must be bound to token
     * @param baseTokenId TokenID of a base token
     * @param packedLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits ActiveLayersChanged
     */
    function setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        external
        virtual
    {
        _setActiveLayers(baseTokenId, packedLayerIds);
    }

    function _burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) internal virtual {
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        bytes32 traitSeed = packedBatchRandomness;

        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();

        // todo: try to batch with arrays by LayerType, fetching distribution for type,
        unchecked {
            // todo: revisit if via_ir = true
            uint256 length = layerTokenIds.length;
            uint256 i;
            for (; i < length; ) {
                uint256 tokenId = layerTokenIds[i];

                // check owner of layer
                if (ownerOf(tokenId) != msg.sender) {
                    revert NotOwner();
                }

                // check layer
                if (tokenId % NUM_TOKENS_PER_SET == 0) {
                    revert CannotBindBase();
                }
                bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
                    tokenId,
                    traitSeed
                );
                uint256 layerId = getLayerId(tokenId, layerSeed);

                // check for duplicates
                uint256 layerIdBitMap = layerId.toBitMap();
                if (bindings & layerIdBitMap > 0) {
                    revert LayerAlreadyBound();
                }

                bindings |= layerIdBitMap;
                _burn(tokenId);
                ++i;
            }
        }
        _setBoundLayersAndEmitEvent(baseTokenId, bindings);
    }

    function _burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        internal
        virtual
    {
        // check ownership
        if (
            ownerOf(baseTokenId) != msg.sender ||
            ownerOf(layerTokenId) != msg.sender
        ) {
            revert NotOwner();
        }

        // check seed
        bytes32 traitSeed = packedBatchRandomness;
        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
            layerTokenId,
            traitSeed
        );
        // check layer
        if (layerTokenId % NUM_TOKENS_PER_SET == 0) {
            revert CannotBindBase();
        }
        uint256 layerId = getLayerId(layerTokenId, layerSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();
        // TODO: necessary?
        uint256 layerIdBitMap = layerId.toBitMap();
        if (bindings & layerIdBitMap > 0) {
            revert LayerAlreadyBound();
        }

        _burn(layerTokenId);
        _setBoundLayersAndEmitEvent(baseTokenId, bindings | layerIdBitMap);
    }

    function _setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        internal
        virtual
    {
        // TODO: explicitly test this
        if (packedLayerIds == 0) {
            revert NoActiveLayers();
        }
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }

        // unpack layers into a single bitmap and check there are no duplicates
        (
            uint256 unpackedLayers,
            uint256 numLayers
        ) = _unpackLayersToBitMapAndCheckForDuplicates(packedLayerIds);

        // check new active layers are all bound to baseTokenId
        uint256 boundLayers = getBoundLayerBitMap(baseTokenId);
        _checkUnpackedIsSubsetOfBound(unpackedLayers, boundLayers);

        // clear all bytes after last non-zero bit on packedLayerIds,
        // since unpacking to bitmap short-circuits on first zero byte
        uint256 maskedPackedLayerIds;
        // num layers can never be >32, so 256 - (numLayers * 8) can never negative-oveflow
        unchecked {
            maskedPackedLayerIds =
                packedLayerIds &
                (type(uint256).max << (256 - (numLayers * 8)));
        }

        _tokenIdToPackedActiveLayers[baseTokenId] = maskedPackedLayerIds;
        emit ActiveLayersChanged(baseTokenId, maskedPackedLayerIds);
    }

    function _setBoundLayersAndEmitEvent(uint256 baseTokenId, uint256 bindings)
        internal
    {
        // 0 is not a valid layerId, so make sure it is not set on bindings.
        bindings = bindings & NOT_0TH_BITMASK;
        _tokenIdToBoundLayers[baseTokenId] = bindings;
        emit LayersBoundToToken(baseTokenId, bindings);
    }

    // CHECK //

    /**
     * @notice Unpack bytepacked layerIds and check that there are no duplicates
     * @param bytePackedLayers uint256 of packed layerIds
     * @return bitMap uint256 of unpacked layerIds
     */
    function _unpackLayersToBitMapAndCheckForDuplicates(
        uint256 bytePackedLayers
    ) internal virtual returns (uint256 bitMap, uint256 numLayers) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } lt(numLayers, 32) {
                numLayers := add(1, numLayers)
            } {
                let layer := byte(numLayers, bytePackedLayers)
                if iszero(layer) {
                    break
                }
                // put copy of bitmap on stack
                let lastBitMap := bitMap
                // OR layer into bitmap
                bitMap := or(bitMap, shl(layer, 1))
                // check equality - if equal, layer is a duplicate
                if eq(lastBitMap, bitMap) {
                    mstore(
                        0,
                        // revert DuplicateActiveLayers()
                        DUPLICATE_ACTIVE_LAYERS_SIGNATURE
                    )
                    revert(0, 4)
                }
            }
        }
    }

    function _checkUnpackedIsSubsetOfBound(uint256 subset, uint256 superset)
        internal
        pure
        virtual
    {
        // superset should be superset of subset, compare union to superset

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(or(superset, subset), superset)) {
                mstore(
                    0,
                    // revert LayerNotBoundToTokenId()
                    LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE
                )
                revert(0, 4)
            }
        }
    }

    function _setMetadataContract(ILayerable _metadataContract)
        internal
        virtual
    {
        metadataContract = _metadataContract;
    }

    /////////////
    // HELPERS //
    /////////////

    /// @dev set 0th bit to 1 in order to make first binding cost cheaper for user
    function _setPlaceholderBinding(uint256 tokenId) internal {
        _tokenIdToBoundLayers[tokenId] = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {RandomTraits} from './RandomTraits.sol';

abstract contract RandomTraitsImpl is RandomTraits {
    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint8 layerType)
    {
        uint256 numTokensPerSet = NUM_TOKENS_PER_SET;

        /// @solidity memory-safe-assembly
        assembly {
            layerType := mod(tokenId, numTokensPerSet)
            if gt(layerType, 5) {
                layerType := 5
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error TradingAlreadyDisabled();
error IncorrectPayment();
error ArrayLengthMismatch(uint256 length1, uint256 length2);
error LayerNotBoundToTokenId();
error DuplicateActiveLayers();
error MultipleVariationsEnabled();
error InvalidLayer(uint256 layer);
error BadDistributions();
error NotOwner();
error BatchNotRevealed();
error LayerAlreadyBound();
error CannotBindBase();
error OnlyBase();
error InvalidLayerType();
error MaxSupply();
error MaxRandomness();
error OnlyCoordinatorCanFulfill(address have, address want);
error UnsafeReveal();
error NoActiveLayers();
error InvalidInitialization();

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
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
    // Reference type for token approval.
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
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
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
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : '';
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
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
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
    function _packedOwnershipOf(uint256 tokenId)
        private
        view
        returns (uint256)
    {
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
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        private
        pure
        returns (uint256 result)
    {
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
    function approve(address to, uint256 tokenId) public virtual override {
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
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
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
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
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

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
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
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
    ) public virtual override {
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
    ) public virtual override {
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
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
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
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

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
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
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

    function _isBurned(uint256 tokenId) internal view returns (bool isBurned) {
        return _packedOwnerships[tokenId] & _BITMASK_BURNED != 0;
    }

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

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            )
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
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
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    _nextExtraData(from, address(0), prevOwnershipPacked)
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

    function _setPackedOwnershipOf(uint256 index, uint256 packed)
        internal
        virtual
    {
        _packedOwnerships[index] = packed;
    }

    function _getPackedOwnershipOf(uint256 index)
        internal
        view
        virtual
        returns (uint256)
    {
        return _packedOwnerships[index];
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Get extra data for token ID
     */
    function _getExtraDataAt(uint256 index)
        internal
        view
        virtual
        returns (uint24 extraData)
    {
        uint256 packed = _packedOwnerships[index];
        /// @solidity memory-safe-assembly
        assembly {
            extraData := shr(_BITPOS_EXTRA_DATA, packed)
        }
    }

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
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << _BITPOS_EXTRA_DATA);
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
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory ptr)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OnChainTraits} from '../traits/OnChainTraits.sol';
import {svg, utils} from '../SVG.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {RandomTraits} from '../traits/RandomTraits.sol';
import {json} from '../lib/JSON.sol';
import {BitMapUtility} from '../lib/BitMapUtility.sol';
import {PackedByteUtility} from '../lib/PackedByteUtility.sol';
import {Layerable} from './Layerable.sol';
import {IImageLayerable} from './IImageLayerable.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {InvalidInitialization} from '../interface/Errors.sol';

contract ImageLayerable is Layerable, IImageLayerable {
    // TODO: different strings impl?
    using Strings for uint256;

    string defaultURI;
    // todo: use different URIs for solo layers and layered layers?
    string baseLayerURI;

    // TODO: add baseLayerURI
    constructor(string memory _defaultURI, address _owner) Layerable(_owner) {
        _initialize(_defaultURI);
    }

    function initialize(address _owner, string memory _defaultURI)
        public
        virtual
    {
        super._initialize(_owner);
        _initialize(_defaultURI);
    }

    function _initialize(string memory _defaultURI) internal virtual {
        if (address(this).code.length > 0) {
            revert InvalidInitialization();
        }
        defaultURI = _defaultURI;
    }

    /// @notice set the default URI for unrevealed tokens
    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    /// @notice set the base URI for layers
    function setBaseLayerURI(string memory _baseLayerURI) public onlyOwner {
        baseLayerURI = _baseLayerURI;
    }

    /**
     * @notice get the complete URI of a set of token traits
     * @param layerId the layerId of the base token
     * @param bindings the bitmap of bound traits
     * @param activeLayers packed array of active layerIds as bytes
     * @param layerSeed the random seed for random generation of traits, used to determine if layers have been revealed
     * @return the complete URI of the token, including image and all attributes
     */
    function getTokenURI(
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) public view virtual override returns (string memory) {
        // return default uri
        if (layerSeed == 0) {
            return _constructJson(getDefaultImageURI(layerId), '');
        }
        // if no bindings, format metadata as an individual NFT
        // check if bindings == 0 or 1; bindable layers will be treated differently
        // TODO: test this if/else
        else if (bindings == 0 || bindings == 1) {
            return
                _constructJson(
                    getLayerImageURI(layerId),
                    json.array(getTraitJson(layerId))
                );
        } else {
            return
                _constructJson(
                    getLayeredTokenImageURI(activeLayers),
                    getBoundAndActiveLayerTraits(bindings, activeLayers)
                );
        }
    }

    /// @notice get the complete SVG for a set of activeLayers
    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory layerImages = '';
        for (uint256 i; i < activeLayers.length; ++i) {
            string memory layerUri = getLayerImageURI(activeLayers[i]);
            layerImages = string.concat(
                layerImages,
                svg.image(layerUri, svg.prop('height', '100%'))
            );
        }

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg">',
                layerImages,
                '</svg>'
            );
    }

    /// @notice get the image URI for a layerId
    function getLayerImageURI(uint256 layerId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string.concat(baseLayerURI, layerId.toString());
    }

    /// @notice get the default URI for a layerId
    function getDefaultImageURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return defaultURI;
    }

    /// @dev helper to wrap imageURI and optional attributes into a JSON object string
    function _constructJson(string memory imageURI, string memory attributes)
        internal
        pure
        returns (string memory)
    {
        if (bytes(attributes).length > 0) {
            string[] memory properties = new string[](2);
            properties[0] = json.property('image', imageURI);
            // attributes should be a JSON array, no need to wrap it in quotes
            properties[1] = json.rawProperty('attributes', attributes);
            return json.objectOf(properties);
        }
        return json.object(json.property('image', imageURI));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interface/Constants.sol';

library PackedByteUtility {
    /**
     * @notice get the byte value of a right-indexed byte within a uint256
     * @param  index right-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at right-indexed index within packedBytes
     */
    function getPackedByteFromRight(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(sub(31, index), packedBytes)
        }
    }

    /**
     * @notice get the byte value of a left-indexed byte within a uint256
     * @param  index left-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at left-indexed index within packedBytes
     */
    function getPackedByteFromLeft(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(index, packedBytes)
        }
    }

    /**
     * @notice unpack elements of a packed byte array into a bitmap. Short-circuits at first 0-byte.
     * @param  packedBytes uint256 of bytes
     * @return unpacked - 1-indexed bitMap of all byte values contained in packedBytes up until the first 0-byte
     */
    function unpackBytesToBitMap(uint256 packedBytes)
        internal
        pure
        returns (uint256 unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for {
                let i := 0
            } lt(i, 32) {
                i := add(i, 1)
            } {
                // this is the ID of the layer, eg, 1, 5, 253
                let byteVal := byte(i, packedBytes)
                // don't count zero bytes
                if iszero(byteVal) {
                    break
                }
                // byteVals are 1-indexed because we're shifting 1 by the value of the byte
                unpacked := or(unpacked, shl(byteVal, 1))
            }
        }
    }

    /**
     * @notice pack byte values into a uint256. Note: *will not* short-circuit on first 0-byte
     * @param  arrayOfBytes uint256[] of byte values
     * @return packed uint256 of packed bytes
     */
    function packArrayOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256 packed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let arrayOfBytesIndexPtr := add(arrayOfBytes, 0x20)
            let arrayOfBytesLength := mload(arrayOfBytes)
            if gt(arrayOfBytesLength, 32) {
                arrayOfBytesLength := 32
            }
            let finalI := shl(3, arrayOfBytesLength)
            let i
            for {

            } lt(i, finalI) {
                arrayOfBytesIndexPtr := add(0x20, arrayOfBytesIndexPtr)
                i := add(8, i)
            } {
                packed := or(
                    packed,
                    shl(sub(248, i), mload(arrayOfBytesIndexPtr))
                )
            }
        }
    }

    /**
     * @notice Unpack a packed uint256 of bytes into a uint256 array of byte values. Short-circuits on first 0-byte.
     * @param  packedByteArray The packed uint256 of bytes to unpack
     * @return unpacked uint256[] The unpacked uint256 array of bytes
     */
    function unpackByteArray(uint256 packedByteArray)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            unpacked := mload(0x40)
            let unpackedIndexPtr := add(0x20, unpacked)
            let maxUnpackedIndexPtr := add(unpackedIndexPtr, shl(5, 32))
            let numBytes
            for {

            } lt(unpackedIndexPtr, maxUnpackedIndexPtr) {
                unpackedIndexPtr := add(0x20, unpackedIndexPtr)
                numBytes := add(1, numBytes)
            } {
                let byteVal := byte(numBytes, packedByteArray)
                if iszero(byteVal) {
                    break
                }
                mstore(unpackedIndexPtr, byteVal)
            }
            // store the number of layers at the pointer to unpacked array
            mstore(unpacked, numBytes)
            // update free mem pointer to be old mem ptr + 0x20 (32-byte array length) + 0x20 * numLayers (each 32-byte element)
            mstore(0x40, add(unpacked, add(0x20, shl(5, numBytes))))
        }
    }

    /**
     * @notice given a uint256 packed array of bytes, pack a byte at an index from the left
     * @param packedBytes existing packed bytes
     * @param byteToPack byte to pack into packedBytes
     * @param index index to pack byte at
     * @return newPackedBytes with byteToPack at index
     */
    function packByteAtIndex(
        uint256 packedBytes,
        uint256 byteToPack,
        uint256 index
    ) internal pure returns (uint256 newPackedBytes) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculate left-indexed bit offset of byte within packedBytes
            let byteOffset := sub(248, shl(3, index))
            // create a mask to clear the bits we're about to overwrite
            let mask := xor(MAX_INT, shl(byteOffset, 0xff))
            // copy packedBytes to newPackedBytes, clearing the relevant bits
            newPackedBytes := and(packedBytes, mask)
            // shift the byte to the offset and OR it into newPackedBytes
            newPackedBytes := or(newPackedBytes, shl(byteOffset, byteToPack))
        }
    }

    /// @dev less efficient logic for packing >32 bytes into >1 uint256
    function packArraysOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 arrayOfBytesLength = arrayOfBytes.length;
        uint256[] memory packed = new uint256[](
            (arrayOfBytesLength - 1) / 32 + 1
        );
        uint256 workingWord = 0;
        for (uint256 i = 0; i < arrayOfBytesLength; ) {
            // OR workingWord with this byte shifted by byte within the word
            workingWord |= uint256(arrayOfBytes[i]) << (8 * (31 - (i % 32)));

            // if we're on the last byte of the word, store in array
            if (i % 32 == 31) {
                uint256 j = i / 32;
                packed[j] = workingWord;
                workingWord = 0;
            }
            unchecked {
                ++i;
            }
        }
        if (arrayOfBytesLength % 32 != 0) {
            packed[packed.length - 1] = workingWord;
        }

        return packed;
    }

    /// @dev less efficient logic for unpacking >1 uint256s into >32 byte values
    function unpackByteArrays(uint256[] memory packedByteArrays)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 packedByteArraysLength = packedByteArrays.length;
        uint256[] memory unpacked = new uint256[](packedByteArraysLength * 32);
        for (uint256 i = 0; i < packedByteArraysLength; ) {
            uint256 packedByteArray = packedByteArrays[i];
            uint256 j = 0;
            for (; j < 32; ) {
                uint256 unpackedByte = getPackedByteFromLeft(
                    j,
                    packedByteArray
                );
                if (unpackedByte == 0) {
                    break;
                }
                unpacked[i * 32 + j] = unpackedByte;
                unchecked {
                    ++j;
                }
            }
            if (j < 32) {
                break;
            }
            unchecked {
                ++i;
            }
        }
        return unpacked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interface/Constants.sol';

library BitMapUtility {
    /**
     * @notice Convert a byte value into a bitmap, where the bit at position val is set to 1, and all others 0
     * @param  val byte value to convert to bitmap
     * @return bitmap of val
     */
    function toBitMap(uint256 val) internal pure returns (uint256 bitmap) {
        /// @solidity memory-safe-assembly
        assembly {
            bitmap := shl(val, 1)
        }
    }

    /**
     * @notice get the intersection of two bitMaps by ANDing them together
     * @param  target first bitmap
     * @param  test second bitmap
     * @return result bitmap with only bits active in both bitmaps set to 1
     */
    function intersect(uint256 target, uint256 test)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(target, test)
        }
    }

    /**
     * @notice check if bitmap has byteVal set to 1
     * @param  target first bitmap
     * @param  byteVal bit position to check in target
     * @return result true if bitmap contains byteVal
     */
    function contains(uint256 target, uint256 byteVal)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(shr(byteVal, target), 1)
        }
    }

    /**
     * @notice check if union of two bitmaps is equal to the first
     * @param  superset first bitmap
     * @param  subset second bitmap
     * @return result true if superset is a superset of subset, false otherwise
     */
    function isSupersetOf(uint256 superset, uint256 subset)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := eq(superset, or(superset, subset))
        }
    }

    /**
     * @notice unpack a bitmap into an array of included byte values
     * @param  bitMap bitMap to unpack into byte values
     * @return unpacked array of byte values included in bitMap, sorted from smallest to largest
     */
    function unpackBitMap(uint256 bitMap)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(bitMap) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x20))
                return(freePtr, 0x20)
            }
            function lsb(x) -> leastSignificantBit {
                if iszero(and(x, _128_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 128)
                    x := shr(128, x)
                }
                if iszero(and(x, _64_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 64)
                    x := shr(64, x)
                }
                if iszero(and(x, _32_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 32)
                    x := shr(32, x)
                }
                if iszero(and(x, _16_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 16)
                    x := shr(16, x)
                }
                if iszero(and(x, _8_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 8)
                    x := shr(8, x)
                }
                if iszero(and(x, _4_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 4)
                    x := shr(4, x)
                }
                if iszero(and(x, _2_MASK)) {
                    leastSignificantBit := add(leastSignificantBit, 2)
                    x := shr(2, x)
                }
                if iszero(and(x, _1_MASK)) {
                    // No need to shift x any more.
                    leastSignificantBit := add(leastSignificantBit, 1)
                }
            }

            // set unpacked ptr to free mem
            unpacked := mload(0x40)
            // get ptr to first index of array
            let unpackedIndexPtr := add(unpacked, 0x20)

            let numLayers
            for {

            } bitMap {
                unpackedIndexPtr := add(unpackedIndexPtr, 0x20)
            } {
                // store the index of the lsb at the index in the array
                mstore(unpackedIndexPtr, lsb(bitMap))
                // drop the lsb from the bitMap
                bitMap := and(bitMap, sub(bitMap, 1))
                // increment numLayers
                numLayers := add(numLayers, 1)
            }
            // store the number of layers at the pointer to unpacked array
            mstore(unpacked, numLayers)
            // update free mem pointer to first free slot after unpacked array
            mstore(0x40, unpackedIndexPtr)
        }
    }

    /**
     * @notice pack an array of byte values into a bitmap
     * @param  uints array of byte values to pack into bitmap
     * @return bitMap of byte values
     */
    function uintsToBitMap(uint256[] memory uints)
        internal
        pure
        returns (uint256 bitMap)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // get pointer to first index of array
            let uintsIndexPtr := add(uints, 0x20)
            // get pointer to first word after final index of array
            let finalUintsIndexPtr := add(uintsIndexPtr, shl(5, mload(uints)))
            // loop until we reach the end of the array
            for {

            } lt(uintsIndexPtr, finalUintsIndexPtr) {
                uintsIndexPtr := add(uintsIndexPtr, 0x20)
            } {
                // set the bit at left-index 'uint' to 1
                bitMap := or(bitMap, shl(mload(uintsIndexPtr), 1))
            }
        }
    }

    /**
     * @notice Finds the zero-based index of the first one (right-indexed) in the binary representation of x.
     * @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
     * @param x The uint256 number for which to find the index of the most significant bit.
     * @return mostSignificantBit The index of the most significant bit as an uint256.
     * from: https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol, ported to pure assembly
     */
    function msb(uint256 x) internal pure returns (uint256 mostSignificantBit) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, _2_128)) {
                x := shr(128, x)
                mostSignificantBit := add(mostSignificantBit, 128)
            }
            if iszero(lt(x, _2_64)) {
                x := shr(64, x)
                mostSignificantBit := add(mostSignificantBit, 64)
            }
            if iszero(lt(x, _2_32)) {
                x := shr(32, x)
                mostSignificantBit := add(mostSignificantBit, 32)
            }
            if iszero(lt(x, _2_16)) {
                x := shr(16, x)
                mostSignificantBit := add(mostSignificantBit, 16)
            }
            if iszero(lt(x, _2_8)) {
                x := shr(8, x)
                mostSignificantBit := add(mostSignificantBit, 8)
            }
            if iszero(lt(x, _2_4)) {
                x := shr(4, x)
                mostSignificantBit := add(mostSignificantBit, 4)
            }
            if iszero(lt(x, _2_2)) {
                x := shr(2, x)
                mostSignificantBit := add(mostSignificantBit, 2)
            }
            if iszero(lt(x, _2_1)) {
                // No need to shift x any more.
                mostSignificantBit := add(mostSignificantBit, 1)
            }
        }
    }

    /**
     * @notice Finds the zero-based index of the first one (left-indexed) in the binary representation of x
     * @param x The uint256 number for which to find the index of the least significant bit.
     * @return leastSignificantBit The index of the least significant bit as an uint256.
     */
    function lsb(uint256 x)
        internal
        pure
        returns (uint256 leastSignificantBit)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                mstore(0, 0)
                return(0, 0x20)
            }
            if iszero(and(x, _128_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 128)
                x := shr(128, x)
            }
            if iszero(and(x, _64_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 64)
                x := shr(64, x)
            }
            if iszero(and(x, _32_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 32)
                x := shr(32, x)
            }
            if iszero(and(x, _16_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 16)
                x := shr(16, x)
            }
            if iszero(and(x, _8_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 8)
                x := shr(8, x)
            }
            if iszero(and(x, _4_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 4)
                x := shr(4, x)
            }
            if iszero(and(x, _2_MASK)) {
                leastSignificantBit := add(leastSignificantBit, 2)
                x := shr(2, x)
            }
            if iszero(and(x, _1_MASK)) {
                // No need to shift x any more.
                leastSignificantBit := add(leastSignificantBit, 1)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DisplayType} from './Enums.sol';

struct Attribute {
    string traitType;
    string value;
    DisplayType displayType;
}

// TODO: just pack these into a uint256 bytearray
struct LayerVariation {
    uint8 layerId;
    uint8 numVariations;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILayerable {
    function getLayerImageURI(uint256 layerId)
        external
        view
        returns (string memory);

    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundLayerTraits(uint256 bindings)
        external
        view
        returns (string memory);

    function getActiveLayerTraits(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundAndActiveLayerTraits(
        uint256 bindings,
        uint256[] calldata activeLayers
    ) external view returns (string memory);

    function getTokenURI(
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OnChainTraits} from '../traits/OnChainTraits.sol';
import {svg, utils} from '../SVG.sol';
import {RandomTraits} from '../traits/RandomTraits.sol';
import {json} from '../lib/JSON.sol';
import {BitMapUtility} from '../lib/BitMapUtility.sol';
import {PackedByteUtility} from '../lib/PackedByteUtility.sol';
import {ILayerable} from './ILayerable.sol';
import {InvalidInitialization} from '../interface/Errors.sol';

abstract contract Layerable is ILayerable, OnChainTraits {
    using BitMapUtility for uint256;

    constructor(address _owner) {
        _initialize(_owner);
    }

    function initialize(address _owner) external virtual {
        _initialize(_owner);
    }

    function _initialize(address _owner) internal virtual {
        if (address(this).code.length > 0) {
            revert InvalidInitialization();
        }
        _transferOwnership(_owner);
    }

    /**
     * @notice get the complete URI of a set of token traits
     * @param layerId the layerId of the base token
     * @param bindings the bitmap of bound traits
     * @param activeLayers packed array of active layerIds as bytes
     * @param layerSeed the random seed for random generation of traits, used to determine if layers have been revealed
     * @return the complete URI of the token, including image and all attributes
     */
    function getTokenURI(
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) public view virtual returns (string memory);

    /// @notice get the complete SVG for a set of activeLayers
    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        public
        view
        virtual
        returns (string memory);

    /// @notice get the image URI for a layerId
    function getLayerImageURI(uint256 layerId)
        public
        view
        virtual
        returns (string memory);

    /// @notice get stringified JSON array of bound layer traits
    function getBoundLayerTraits(uint256 bindings)
        public
        view
        returns (string memory)
    {
        return json.arrayOf(_getBoundLayerTraits(bindings & ~uint256(0)));
    }

    /// @notice get stringified JSON array of active layer traits
    function getActiveLayerTraits(uint256[] calldata activeLayers)
        public
        view
        returns (string memory)
    {
        return json.arrayOf(_getActiveLayerTraits(activeLayers));
    }

    /// @notice get stringified JSON array of combined bound and active layer traits
    function getBoundAndActiveLayerTraits(
        uint256 bindings,
        uint256[] calldata activeLayers
    ) public view returns (string memory) {
        string[] memory layerTraits = _getBoundLayerTraits(bindings);
        string[] memory activeLayerTraits = _getActiveLayerTraits(activeLayers);
        return json.arrayOf(layerTraits, activeLayerTraits);
    }

    /// @dev get array of stringified trait json for bindings
    function _getBoundLayerTraits(uint256 bindings)
        internal
        view
        returns (string[] memory layerTraits)
    {
        uint256[] memory boundLayers = BitMapUtility.unpackBitMap(bindings);
        layerTraits = new string[](boundLayers.length);
        for (uint256 i; i < boundLayers.length; ++i) {
            layerTraits[i] = getTraitJson(boundLayers[i]);
        }
    }

    /// @dev get array of stringified trait json for active layers. Prepends "Active" to trait title.
    // eg 'Background' -> 'Active Background'
    function _getActiveLayerTraits(uint256[] calldata activeLayers)
        internal
        view
        returns (string[] memory activeLayerTraits)
    {
        activeLayerTraits = new string[](activeLayers.length);
        for (uint256 i; i < activeLayers.length; ++i) {
            activeLayerTraits[i] = getTraitJson(activeLayers[i], 'Active');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PackedByteUtility} from '../lib/PackedByteUtility.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {LayerType} from '../interface/Enums.sol';
import {BAD_DISTRIBUTIONS_SIGNATURE} from '../interface/Constants.sol';
import {BadDistributions, InvalidLayerType} from '../interface/Errors.sol';
import {BatchVRFConsumer} from '../vrf/BatchVRFConsumer.sol';

abstract contract RandomTraits is BatchVRFConsumer {
    using Strings for uint256;

    // 32 possible traits per layerType given uint8 distributions
    // except final trait type, which has 31, because 0 is not a valid layerId.
    // Function getLayerId will check if layerSeed is less than the distribution,
    // so traits distribution cutoffs should be sorted left-to-right
    // ie smallest packed 8-bit segment should be the leftmost 8 bits
    // TODO: does this mean for N < 32 traits, there should be N-1 distributions?
    mapping(uint8 => uint256) layerTypeToPackedDistributions;

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId
    )
        BatchVRFConsumer(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId
        )
    {}

    /////////////
    // SETTERS //
    /////////////

    /**
     * @notice Set the probability distribution for up to 32 different layer traitIds
     * @param layerType layer type to set distribution for
     * @param distribution a uint256 comprised of sorted, packed bytes
     *  that will be compared against a random byte to determine the layerId
     *  for a given tokenId
     */
    function setLayerTypeDistribution(uint8 layerType, uint256 distribution)
        public
        virtual
        onlyOwner
    {
        _setLayerTypeDistribution(layerType, distribution);
    }

    /**
     * @notice Set layer type distributions for multiple layer types
     * @param layerTypes layer types to set distribution for
     * @param distributions an array of uint256s comprised of sorted, packed bytes
     *  that will be compared against a random byte to determine the layerId
     *  for a given tokenId
     */
    function setLayerTypeDistributions(
        uint8[] memory layerTypes,
        uint256[] memory distributions
    ) public virtual onlyOwner {
        for (uint8 i = 0; i < layerTypes.length; i++) {
            _setLayerTypeDistribution(layerTypes[i], distributions[i]);
        }
    }

    /**
     * @notice calculate the 8-bit seed for a layer by hashing the packedBatchRandomness, tokenId, and layerType together
     * and truncating to 8 bits
     * @param tokenId tokenId to get seed for
     * @param layerType layer type to get seed for
     * @param seed packedBatchRandomness
     * @return layerSeed - 8-bit seed for the given tokenId and layerType
     */
    function getLayerSeed(
        uint256 tokenId,
        uint8 layerType,
        bytes32 seed
    ) internal pure returns (uint8 layerSeed) {
        /// @solidity memory-safe-assembly
        assembly {
            // store seed in first slot of scratch memory
            mstore(0x00, seed)
            // pack tokenId and layerType into one 32-byte slot by shifting tokenId to the left 1 byte
            // tokenIds are sequential and MAX_NUM_SETS * NUM_TOKENS_PER_SET is guaranteed to be < 2**248
            let combinedIdType := or(shl(8, tokenId), layerType)
            mstore(0x20, combinedIdType)
            layerSeed := keccak256(0x00, 0x40)
        }
    }

    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 tokenId)
        public
        view
        virtual
        returns (uint8 layerType);

    /**
     * @notice Get the layerId for a given tokenId by hashing tokenId with its layer type and random seed,
     * and then comparing the final byte against the appropriate distributions
     */
    function getLayerId(uint256 tokenId) public view virtual returns (uint256) {
        return getLayerId(tokenId, getRandomnessForTokenId(tokenId));
    }

    /**
     * @dev perform fewer SLOADs by passing seed as parameter
     */
    function getLayerId(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        returns (uint256)
    {
        uint8 layerType = getLayerType(tokenId);
        uint256 layerSeed = getLayerSeed(tokenId, layerType, seed);
        uint256 distributions = layerTypeToPackedDistributions[layerType];
        return getLayerId(layerType, layerSeed, distributions);
    }

    /**
     * @notice calculate the layerId for a given layerType, seed, and distributions.
     * @param layerType of layer
     * @param layerSeed uint256 random seed for layer (in practice will be truncated to 8 bits)
     * @param distributions uint256 packed distributions of layerIds
     * @return layerId limited to 8 bits
     *
     * @dev If the last packed byte is <255, any seed larger than the last packed byte
     *      will be assigned to the index after the last packed byte, unless the last
     *      packed byte is index 31, in which case, it will default to 31.
     *      LayerId is calculated like: index + 1 + 32 * layerType
     *
     * examples:
     * LayerSeed: 0x00
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 0 (LayerId: 0 + 1 + 32 * layerType)
     *
     * LayerSeed: 0x01
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 1 (LayerId: 1 + 1 + 32 * layerType)
     *
     * LayerSeed: 0xFF
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 7 (LayerId: 7 + 1 + 32 * layerType)
     *
     * LayerSeed: 0xFF
     * Distributions: [01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20]
     * Calculated index: 31 (LayerId: 31 + 1 + 32 * layerType)
     */
    function getLayerId(
        uint8 layerType,
        uint256 layerSeed,
        uint256 distributions
    ) internal pure returns (uint256 layerId) {
        /// @solidity memory-safe-assembly
        assembly {
            function revertWithBadDistributions() {
                mstore(0, BAD_DISTRIBUTIONS_SIGNATURE)
                revert(0, 4)
            }

            // declare i outside of loop in case final distribution val is less than seed
            let i
            // iterate over distribution values until we find one that our layer seed is less than
            for {

            } lt(i, 32) {
                i := add(1, i)
            } {
                let dist := byte(i, distributions)
                if iszero(dist) {
                    if gt(i, 0) {
                        // if we've reached end of distributions, check layer type != 7
                        // otherwise if layerSeed is less than the last distribution,
                        // the layerId calculation will evaluate to 256 (overflow)
                        if eq(i, 31) {
                            if eq(layerType, 7) {
                                revertWithBadDistributions()
                            }
                        }
                        // if distribution is 0, and it's not the first, we've reached the end of the list
                        // return i + 1 + 32 * layerType
                        layerId := add(add(1, i), shl(5, layerType))
                        break
                    }
                    // first element should never be 0; distributions are invalid
                    revertWithBadDistributions()
                }
                if lt(layerSeed, dist) {
                    // if i is 31 here, math will overflow here if layerType == 7
                    // 31 + 1 + 32 * 7 = 256, which is too large for a uint8
                    if and(eq(i, 31), eq(layerType, 7)) {
                        revertWithBadDistributions()
                    }

                    // layerIds are 1-indexed, so add 1 to i
                    layerId := add(add(1, i), shl(5, layerType))
                    break
                }
            }
            // if i is 32, we've reached the end of the list and should default to the last id
            if eq(i, 32) {
                // math will overflow here if layerType == 7
                // 32 + 32 * 7 = 256, which is too large for a uint8
                if eq(layerType, 7) {
                    revertWithBadDistributions()
                }
                // return previous layerId
                layerId := add(i, shl(5, layerType))
            }
        }
    }

    function _setLayerTypeDistribution(uint8 layerType, uint256 distribution)
        internal
    {
        if (layerType > 7) {
            revert InvalidLayerType();
        }
        layerTypeToPackedDistributions[layerType] = distribution;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant NOT_0TH_BITMASK = 2**256 - 2;
uint256 constant MAX_INT = 2**256 - 1;
uint136 constant _2_128 = 2**128;
uint72 constant _2_64 = 2**64;
uint40 constant _2_32 = 2**32;
uint24 constant _2_16 = 2**16;
uint16 constant _2_8 = 2**8;
uint8 constant _2_4 = 2**4;
uint8 constant _2_2 = 2**2;
uint8 constant _2_1 = 2**1;

uint128 constant _128_MASK = 2**128 - 1;
uint64 constant _64_MASK = 2**64 - 1;
uint32 constant _32_MASK = 2**32 - 1;
uint16 constant _16_MASK = 2**16 - 1;
uint8 constant _8_MASK = 2**8 - 1;
uint8 constant _4_MASK = 2**4 - 1;
uint8 constant _2_MASK = 2**2 - 1;
uint8 constant _1_MASK = 2**1 - 1;

uint256 constant DUPLICATE_ACTIVE_LAYERS_SIGNATURE = 0x6411ce7500000000000000000000000000000000000000000000000000000000;
uint256 constant LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE = 0xa385f80500000000000000000000000000000000000000000000000000000000;
uint256 constant BAD_DISTRIBUTIONS_SIGNATURE = 0x338096f700000000000000000000000000000000000000000000000000000000;
uint256 constant MULTIPLE_VARIATIONS_ENABLED_SIGNATURE = 0x4d2e939600000000000000000000000000000000000000000000000000000000;
uint256 constant BATCH_NOT_REVEALED_SIGNATURE = 0x729b0f7500000000000000000000000000000000000000000000000000000000;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BoundLayerableEvents {
    event LayersBoundToToken(
        uint256 indexed tokenId,
        uint256 indexed boundLayersBitmap
    );

    event ActiveLayersChanged(
        uint256 indexed tokenId,
        uint256 indexed activeLayersBytearray
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum DisplayType {
    String,
    Number,
    Date,
    BoostPercent,
    BoostNumber
}

// TODO: generalize this, probably uint8s
enum LayerType {
    PORTRAIT,
    BACKGROUND,
    TEXTURE,
    OBJECT,
    OBJECT2,
    BORDER
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
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
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

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
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
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

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {PackedByteUtility} from '../lib/PackedByteUtility.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {json} from '../lib/JSON.sol';
import {ArrayLengthMismatch} from '../interface/Errors.sol';
import {DisplayType} from '../interface/Enums.sol';
import {Attribute} from '../interface/Structs.sol';

abstract contract OnChainTraits is Ownable {
    using Strings for uint256;

    mapping(uint256 => Attribute) public traitAttributes;

    function setAttribute(uint256 traitId, Attribute calldata attribute)
        public
        onlyOwner
    {
        traitAttributes[traitId] = attribute;
    }

    function setAttributes(
        uint256[] calldata traitIds,
        Attribute[] calldata attributes
    ) public onlyOwner {
        if (traitIds.length != attributes.length) {
            revert ArrayLengthMismatch(traitIds.length, attributes.length);
        }
        for (uint256 i; i < traitIds.length; ++i) {
            traitAttributes[traitIds[i]] = attributes[i];
        }
    }

    function getTraitJson(uint256 traitId) public view returns (string memory) {
        Attribute memory attribute = traitAttributes[traitId];

        string memory properties = string.concat(
            json.property('trait_type', attribute.traitType),
            ','
        );
        return _getTraitJson(properties, attribute);
    }

    function getTraitJson(uint256 traitId, string memory qualifier)
        public
        view
        returns (string memory)
    {
        Attribute memory attribute = traitAttributes[traitId];

        string memory properties = string.concat(
            json.property(
                'trait_type',
                string.concat(qualifier, ' ', attribute.traitType)
            ),
            ','
        );
        return _getTraitJson(properties, attribute);
    }

    function displayTypeJson(string memory displayTypeString)
        internal
        pure
        returns (string memory)
    {
        return json.property('display_type', displayTypeString);
    }

    function _getTraitJson(string memory properties, Attribute memory attribute)
        internal
        pure
        returns (string memory)
    {
        // todo: probably don't need this for layers, but good for generic
        DisplayType displayType = attribute.displayType;
        if (displayType != DisplayType.String) {
            string memory displayTypeString;
            if (displayType == DisplayType.Number) {
                displayTypeString = displayTypeJson('number');
            } else if (attribute.displayType == DisplayType.Date) {
                displayTypeString = displayTypeJson('date');
            } else if (attribute.displayType == DisplayType.BoostPercent) {
                displayTypeString = displayTypeJson('boost_percent');
            } else if (attribute.displayType == DisplayType.BoostNumber) {
                displayTypeString = displayTypeJson('boost_number');
            }
            properties = string.concat(properties, displayTypeString, ',');
        }
        properties = string.concat(
            properties,
            json.property('value', attribute.value)
        );
        return json.object(properties);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {utils} from './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('image', string.concat(prop('href', _href), ' ', _props));
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<', _tag, ' ', _props, '/>');
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
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
pragma solidity ^0.8.4;

import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';

library json {
    using Strings for uint256;

    /**
     * @notice enclose a string in {braces}
     * @param  value string to enclose in braces
     * @return string of {value}
     */
    function object(string memory value) internal pure returns (string memory) {
        return string.concat('{', value, '}');
    }

    /**
     * @notice enclose a string in [brackets]
     * @param value string to enclose in brackets
     * @return string of [value]
     */
    function array(string memory value) internal pure returns (string memory) {
        return string.concat('[', value, ']');
    }

    /**
     * @notice enclose name and value with quotes, and place a colon "between":"them"
     * @param name name of property
     * @param value value of property
     * @return string of "name":"value"
     */
    function property(string memory name, string memory value)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', name, '":"', value, '"');
    }

    /**
     * @notice enclose name with quotes, but not rawValue, and place a colon "between":them
     * @param name name of property
     * @param rawValue raw value of property, which will not be enclosed in quotes
     * @return string of "name":value
     */
    function rawProperty(string memory name, string memory rawValue)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', name, '":', rawValue);
    }

    /**
     * @notice comma-join an array of properties and {"enclose":"them","in":"braces"}
     * @param properties array of properties to join
     * @return string of {"name":"value","name":"value",...}
     */
    function objectOf(string[] memory properties)
        internal
        pure
        returns (string memory)
    {
        if (properties.length == 0) {
            return object('');
        }
        string memory result = properties[0];
        for (uint256 i = 1; i < properties.length; ++i) {
            result = string.concat(result, ',', properties[i]);
        }
        return object(result);
    }

    /**
     * @notice comma-join an array of values and enclose them [in,brackets]
     * @param values array of values to join
     * @return string of [value,value,...]
     */
    function arrayOf(string[] memory values)
        internal
        pure
        returns (string memory)
    {
        return array(_commaJoin(values));
    }

    /**
     * @notice comma-join two arrays of values and [enclose,them,in,brackets]
     * @param values1 first array of values to join
     * @param values2 second array of values to join
     * @return string of [values1_0,values1_1,values2_0,values2_1...]
     */
    function arrayOf(string[] memory values1, string[] memory values2)
        internal
        pure
        returns (string memory)
    {
        if (values1.length == 0) {
            return arrayOf(values2);
        } else if (values2.length == 0) {
            return arrayOf(values1);
        }
        return
            array(string.concat(_commaJoin(values1), ',', _commaJoin(values2)));
    }

    /**
     * @notice enclose a string in double "quotes"
     * @param str string to enclose in quotes
     * @return string of "value"
     */
    function quote(string memory str) internal pure returns (string memory) {
        return string.concat('"', str, '"');
    }

    /**
     * @notice comma-join an array of strings
     * @param values array of strings to join
     * @return string of value,value,...
     */
    function _commaJoin(string[] memory values)
        internal
        pure
        returns (string memory)
    {
        return _join(values, ',');
    }

    /**
     * @notice join an array of strings with a specified separator
     * @param values array of strings to join
     * @param separator separator to join with
     * @return string of value<separator>value<separator>...
     */
    function _join(string[] memory values, string memory separator)
        internal
        pure
        returns (string memory)
    {
        if (values.length == 0) {
            return '';
        }
        string memory result = values[0];
        for (uint256 i = 1; i < values.length; ++i) {
            result = string.concat(result, separator, values[i]);
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IImageLayerable {
    function setBaseLayerURI(string calldata baseLayerURI) external;

    function setDefaultURI(string calldata baseLayerURI) external;

    function getDefaultImageURI(uint256 layerId)
        external
        returns (string memory);
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
pragma solidity ^0.8.4;

import {VRFConsumerBaseV2} from 'chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import {VRFCoordinatorV2Interface} from 'chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {ERC721A} from '../token/ERC721A.sol';
import {_32_MASK, BATCH_NOT_REVEALED_SIGNATURE} from '../interface/Constants.sol';
import {BatchNotRevealed, MaxRandomness, OnlyCoordinatorCanFulfill, UnsafeReveal} from '../interface/Errors.sol';

contract BatchVRFConsumer is ERC721A, Ownable {
    // VRF config
    uint8 constant MAX_BATCH = 8;
    uint16 constant NUM_CONFIRMATIONS = 7;
    uint32 constant CALLBACK_GAS_LIMIT = 300_000;
    // todo: mutable?
    uint64 immutable SUBSCRIPTION_ID;
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // token config
    // use uint240 to ensure tokenId can never be > 2**248 for efficient hashing
    uint240 immutable MAX_NUM_SETS;
    uint8 immutable NUM_TOKENS_PER_SET;
    uint248 immutable NUM_TOKENS_PER_RANDOM_BATCH;
    uint256 immutable MAX_TOKEN_ID;

    bytes32 public packedBatchRandomness;
    uint248 revealBatch;

    // allow unsafe revealing of an uncompleted batch, ie, in the case of a stalled mint
    bool forceUnsafeReveal;

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId
    ) ERC721A(name, symbol) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        MAX_NUM_SETS = maxNumSets;
        NUM_TOKENS_PER_SET = numTokensPerSet;
        SUBSCRIPTION_ID = subscriptionId;
        NUM_TOKENS_PER_RANDOM_BATCH =
            (uint248(MAX_NUM_SETS) * uint248(NUM_TOKENS_PER_SET)) /
            uint248(MAX_BATCH);
        MAX_TOKEN_ID = uint256(MAX_NUM_SETS) * uint256(NUM_TOKENS_PER_SET);
    }

    /**
     * @notice when true, allow revealing the rest of a batch that has not completed minting yet
     *         This is "unsafe" because it becomes possible to know the layerIds of unminted tokens from the batch
     */
    function setForceUnsafeReveal(bool force) external onlyOwner {
        forceUnsafeReveal = force;
    }

    /**
     * @notice request random words from the chainlink vrf for each unrevealed batch
     */
    function requestRandomWords(bytes32 keyHash)
        external
        onlyOwner
        returns (uint256)
    {
        (uint32 numBatches, ) = _checkAndReturnNumBatches();

        // Will revert if subscription is not set and funded.
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                SUBSCRIPTION_ID,
                NUM_CONFIRMATIONS,
                CALLBACK_GAS_LIMIT,
                numBatches
            );
    }

    function getRandomnessForTokenId(uint256 tokenId)
        internal
        view
        returns (bytes32 randomness)
    {
        return getRandomnessForTokenIdFromSeed(tokenId, packedBatchRandomness);
    }

    /**
     * @notice Get the 32-bit randomness for a given tokenId if it's been set, else revert
     * @param tokenId tokenId of the token to get the randomness for
     * @param seed bytes32 seed containing all batches randomness
     * @return randomness 32-bit randomness as bytes32 for the given tokenId
     */
    function getRandomnessForTokenIdFromSeed(uint256 tokenId, bytes32 seed)
        internal
        view
        returns (bytes32 randomness)
    {
        // put immutable variable onto stack
        uint256 numTokensPerRandomBatch = NUM_TOKENS_PER_RANDOM_BATCH;

        /// @solidity memory-safe-assembly
        assembly {
            // use mask to get last 32 bits of shifted packedBatchRandomness
            randomness := and(
                // shift packedBatchRandomness right by batchNum * 32 bits
                shr(
                    // get batch number of token, multiply by 32
                    shl(5, div(tokenId, numTokensPerRandomBatch)),
                    seed
                ),
                _32_MASK
            )
            if eq(randomness, 0) {
                mstore(0, BATCH_NOT_REVEALED_SIGNATURE)
                revert(0, 4)
            }
        }
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != address(COORDINATOR)) {
            revert OnlyCoordinatorCanFulfill(msg.sender, address(COORDINATOR));
        }
        fulfillRandomWords(requestId, randomWords);
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        virtual
    {
        (uint32 numBatches, uint32 _revealBatch) = _checkAndReturnNumBatches();
        bytes32 currSeed = packedBatchRandomness;
        uint256 randomness = randomWords[0];

        uint256 mask = type(uint256).max << (256 - (32 * numBatches));
        uint256 newRandomness = randomness & mask;
        currSeed = bytes32(uint256(currSeed) | newRandomness);
        _revealBatch += numBatches;
        packedBatchRandomness = currSeed;
        revealBatch = _revealBatch;
    }

    /**
     * @notice calculate how many batches need to be revealed, and also get next batch number
     * @return (uint32 numMissingBatches, uint32 _revealBatch) - number missing batches, and the current _revealBatch
     *         index (current batch revealed + 1, or 0 if none)
     */
    function _checkAndReturnNumBatches()
        internal
        view
        returns (uint32, uint32)
    {
        // get next unminted token ID
        uint256 nextTokenId_ = _nextTokenId();
        // get number of fully completed batches
        uint256 numCompletedBatches = nextTokenId_ /
            NUM_TOKENS_PER_RANDOM_BATCH;

        uint32 _revealBatch = uint32(revealBatch);
        // reveal is complete if _revealBatch is >= 8
        if (_revealBatch >= MAX_BATCH) {
            revert MaxRandomness();
        }

        // if equal, next batch has not started minting yet
        bool batchIsInProgress = nextTokenId_ >
            numCompletedBatches * NUM_TOKENS_PER_RANDOM_BATCH &&
            numCompletedBatches != MAX_BATCH;
        bool batchInProgressAlreadyRevealed = _revealBatch >
            numCompletedBatches;
        uint32 numMissingBatches = batchInProgressAlreadyRevealed
            ? 0
            : uint32(numCompletedBatches) - _revealBatch;

        // don't ever reveal batches from which no tokens have been minted
        if (
            batchInProgressAlreadyRevealed ||
            (numMissingBatches == 0 && !batchIsInProgress)
        ) {
            revert UnsafeReveal();
        }
        // increment if batch is in progress
        if (batchIsInProgress && forceUnsafeReveal) {
            ++numMissingBatches;
        }

        return (numMissingBatches, _revealBatch);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4; //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = 48 + uint8(_i - (_i / 10) * 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}