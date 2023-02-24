// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './ExpandableExtensionWithAccessControlV2.sol';
import './ERC1155_NFTCExtended.sol';

/**
 * @title ERC1155_NFTCExtended_Expandable
 * @author @NiftyMike | @Dr3amLabs
 * @dev ERC1155-type contract with expandable token-type system added on.
 */
abstract contract ERC1155_NFTCExtended_Expandable is ExpandableExtensionWithAccessControlV2, ERC1155_NFTCExtended {
    constructor(
        string memory __baseURI,
        bool __allowMaxSupplyIncrease
    ) ERC1155(__baseURI) ExpandableExtensionWithAccessControlV2(__allowMaxSupplyIncrease) {
        // Nothing to do.
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function maxSupply() external view returns (uint256) {
        return _getMaxSupply();
    }

    function _canMint(
        uint256 count,
        uint256 flavorId,
        bool enforceValue,
        uint256 valueSent
    ) internal view returns (FlavorInfoV2 memory) {
        FlavorInfoV2 memory tokenFlavor = _getFlavorInfo(flavorId);
        _checkFlavorIsValid(tokenFlavor);
        _checkCountIsValid(tokenFlavor, count);

        if (enforceValue) {
            _checkValueIsValid(tokenFlavor, count, valueSent);
        }
        if (tokenFlavor.externalValidator != address(0)) {
            _validateCanMint(tokenFlavor, count);
        }

        tokenFlavor.totalMinted += uint64(count);

        return tokenFlavor;
    }

    function _internalMintTokensOfFlavor(address minter, uint256 count, uint256 flavorId) internal {
        // For ERC1155, the tokenId itself is the flavorId.
        _mint(minter, flavorId, count, '');
    }

    function _setFlavorForToken(uint256 tokenId, uint256 flavorId) internal {
        // No-op for ERC1155.
    }

    function getFlavorForToken(uint256 tokenId) external pure returns (uint256) {
        return tokenId;
    }

    function _getFlavorForToken(uint256 tokenId) internal pure returns (uint256) {
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title  ERC1155_NFTCExtended
 * @author @NFTCulture
 * @dev OZ ERC1155 plus NFTC-preferred extensions and add-ons.
 *  - Burnable
 *  - Ownable
 *  - Total Supply Tracking
 *  - URI Updating
 *
 * NOTE: A lot of code lifted from OZ ERC1155Supply (token/ERC1155/extensions/ERC1155Supply.sol)
 */
abstract contract ERC1155_NFTCExtended is ERC1155Burnable, Ownable {
    mapping(uint256 => uint256) private _totalSupply;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155_NFTCExtended.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, 'ERC1155: invalid amount');
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './FlavorInfoManagerV2.sol';
import './IFlavorInfoProviderV2.sol';

// Error Codes
error UnrecognizedFlavorId();
error InvalidValuePayment();
error InvalidAccess();
error CannotChangeMaxSupply();
error InvalidMaxSupply();
error ExceedsMaxSupplyForFlavor();

/**
 * @title ExpandableExtensionV2
 * @author @NiftyMike | @NFTCulture
 * @dev Extension contract for Expandable Token Types.
 */
abstract contract ExpandableExtensionV2 is FlavorInfoManagerV2 {
    bool private immutable ALLOW_MAX_SUPPLY_INCREASE;

    constructor(bool __allowMaxSupplyIncrease) FlavorInfoManagerV2() {
        ALLOW_MAX_SUPPLY_INCREASE = __allowMaxSupplyIncrease;
    }

    function injectFlavorsFromProvider(address __externalProviderAddress) external {
        if (!_canCreate()) revert InvalidAccess();

        IFlavorInfoProviderV2 externalProvider = IFlavorInfoProviderV2(__externalProviderAddress);

        FlavorInfoV2[] memory flavors = externalProvider.provideFlavorInfos();

        for (uint256 idx = 0; idx < flavors.length; idx++) {
            _incrementMaxSupply(flavors[idx].maxSupply);
            _createFlavorInfo(flavors[idx]);
        }
    }

    /**
     * @notice Create a new token flavor.
     *
     * @param __externalValidator - will be shared for all flavors in this batch.
     * @param __ipfsHash - will be shared for all flavors in this batch.
     */
    function createNewTokenFlavors(
        uint256[] calldata __flavorIds,
        uint256[] calldata __prices,
        uint256[] calldata __maxSupplies,
        bytes32[] calldata __uriFragments,
        address __externalValidator,
        string calldata __ipfsHash
    ) external {
        if (!_canCreate()) revert InvalidAccess();

        require(
            __flavorIds.length == __prices.length &&
                __flavorIds.length == __maxSupplies.length &&
                __flavorIds.length == __uriFragments.length,
            'Unmatched arrays'
        );

        for (uint256 idx = 0; idx < __flavorIds.length; idx++) {
            FlavorInfoV2 memory newFlavor = FlavorInfoV2(
                uint64(__flavorIds[idx]),
                uint64(__maxSupplies[idx]),
                0,
                0,
                __externalValidator,
                uint96(__prices[idx]),
                __uriFragments[idx],
                __ipfsHash
            );

            _incrementMaxSupply(newFlavor.maxSupply);
            _createFlavorInfo(newFlavor);
        }
    }

    /**
     * @notice Update a token flavor. All fields other than flavorId are optional.
     *
     * Appropriate zero value should be provided to skip updatin a field.
     *
     * @param force - can be used to force updates to zero values, however this
     * param requires all valid values to be provided.
     */
    function updateTokenFlavor(
        uint256 __flavorId,
        uint256 __price,
        uint256 __maxSupply,
        uint256 __aux,
        bytes32 __uriFragment,
        address __externalValidator,
        string calldata __ipfsHash,
        bool force
    ) external {
        if (!_canUpdate()) revert InvalidAccess();
        if (__maxSupply != 0 && !ALLOW_MAX_SUPPLY_INCREASE) revert CannotChangeMaxSupply();

        FlavorInfoV2 memory previousFlavor = _getFlavorInfo(__flavorId);
        _checkFlavorIsValid(previousFlavor);

        if (force || __price > 0) {
            previousFlavor.price = uint96(__price);
        }

        if (__maxSupply > 0) {
            if (__maxSupply < previousFlavor.totalMinted) revert InvalidMaxSupply();

            if (__maxSupply > previousFlavor.maxSupply) {
                _incrementMaxSupply(__maxSupply - previousFlavor.maxSupply);
            } else {
                _decrementMaxSupply(previousFlavor.maxSupply - __maxSupply);
            }

            previousFlavor.maxSupply = uint64(__maxSupply);
        }

        if (force || __aux > 0) {
            previousFlavor.aux = uint64(__aux);
        }

        if (force || __uriFragment != bytes32(0)) {
            previousFlavor.uriFragment = __uriFragment;
        }

        if (force || __externalValidator != address(0)) {
            previousFlavor.externalValidator = __externalValidator;
        }

        bytes memory tempIpfsHash = bytes(__ipfsHash);
        if (force || tempIpfsHash.length > 0) {
            previousFlavor.ipfsHash = __ipfsHash;
        }

        _updateFlavorInfo(previousFlavor);
    }

    /**
     * @notice Update a price for a batch of Flavors.
     */
    function updateTokenFlavorPrices(uint256[] calldata __flavorIds, uint256 __price) external {
        if (!_canUpdate()) revert InvalidAccess();

        for (uint256 idx = 0; idx < __flavorIds.length; idx++) {
            FlavorInfoV2 memory previousFlavor = _getFlavorInfo(__flavorIds[idx]);
            _checkFlavorIsValid(previousFlavor);
            previousFlavor.price = uint96(__price);
            _updateFlavorInfo(previousFlavor);
        }
    }

    /**
     * @notice Update ipfs hashes for a batch of flavors.
     */
    function updateTokenFlavorHashes(uint256[] calldata __flavorIds, string calldata __ipfsHash) external {
        if (!_canUpdate()) revert InvalidAccess();

        for (uint256 idx = 0; idx < __flavorIds.length; idx++) {
            FlavorInfoV2 memory previousFlavor = _getFlavorInfo(__flavorIds[idx]);
            _checkFlavorIsValid(previousFlavor);
            previousFlavor.ipfsHash = __ipfsHash;
            _updateFlavorInfo(previousFlavor);
        }
    }

    function _checkFlavorIsValid(FlavorInfoV2 memory tokenFlavor) internal pure {
        if (tokenFlavor.flavorId == 0) revert UnrecognizedFlavorId();
    }

    function _checkValueIsValid(FlavorInfoV2 memory tokenFlavor, uint256 count, uint256 valueSent) internal pure {
        uint256 valueNeeded = tokenFlavor.price * count;
        if (valueSent != valueNeeded) revert InvalidValuePayment();
    }

    function _checkCountIsValid(FlavorInfoV2 memory tokenFlavor, uint256 count) internal pure {
        if (tokenFlavor.maxSupply == 0) return; // Open Edition
        if (tokenFlavor.totalMinted + count > tokenFlavor.maxSupply) revert ExceedsMaxSupplyForFlavor();
    }

    function _validateCanMint(FlavorInfoV2 memory tokenFlavor, uint256 count) internal view virtual {
        // This is a hook to allow subclasses to implement checks using the FlavorInfo.externalValidator member.
    }

    function _canCreate() internal view virtual returns (bool);

    function _canUpdate() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/AccessControl.sol';

// NFTC Prerelease Contracts
import './ExpandableExtensionV2.sol';

/**
 * @title ExpandableExtensionWithAccessControlV2
 * @author @NiftyMike | @NFTCulture
 * @dev Adds AccessControl roles onto ExpandableExtensionV2.
 */
abstract contract ExpandableExtensionWithAccessControlV2 is ExpandableExtensionV2, AccessControl {
    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');

    constructor(bool __allowMaxSupplyIncrease) ExpandableExtensionV2(__allowMaxSupplyIncrease) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // CREATOR_ROLE can create new flavors and update existing ones.
        _grantRole(CREATOR_ROLE, msg.sender);
    }

    function _canCreate() internal view override returns (bool) {
        return hasRole(CREATOR_ROLE, msg.sender);
    }

    function _canUpdate() internal view override returns (bool) {
        return hasRole(CREATOR_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfoV2.sol';

/**
 * @title FlavorInfoManagerV2
 * @author @NFTCulture
 */
abstract contract FlavorInfoManagerV2 is IFlavorInfoV2 {
    // Storage for Token Flavors
    mapping(uint256 => FlavorInfoV2) private _flavorInfo;

    uint64[] private _flavorIds;

    uint256 private _maxSupply;

    constructor() {
        _initializeFlavors();

        _maxSupply = _computeMaxSupply();
    }

    function _initializeFlavors() private {
        FlavorInfoV2[] memory initialTokenFlavors = _getInitialFlavors();

        for (uint256 idx = 0; idx < initialTokenFlavors.length; idx++) {
            FlavorInfoV2 memory current = initialTokenFlavors[idx];

            _createFlavorInfo(current);
        }
    }

    function _getInitialFlavors() internal virtual returns (FlavorInfoV2[] memory);

    function getFlavorInfo(uint256 flavorId) external view returns (FlavorInfoV2 memory) {
        return _getFlavorInfo(flavorId);
    }

    function _getFlavorInfo(uint256 flavorId) internal view returns (FlavorInfoV2 memory) {
        return _flavorInfo[flavorId];
    }

    function getFlavors() external view returns (uint64[] memory) {
        return _getFlavors();
    }

    function _getFlavors() internal view returns (uint64[] memory) {
        return _flavorIds;
    }

    function _createFlavorInfo(FlavorInfoV2 memory tokenFlavor) internal {
        // This allows expanding the collection, so we should eventually restrict it.
        _flavorInfo[tokenFlavor.flavorId] = tokenFlavor;
        _flavorIds.push(tokenFlavor.flavorId);
    }

    function _updateFlavorInfo(FlavorInfoV2 memory tokenFlavor) internal {
        // This allows editing max supply, so we should eventually restrict it.
        _flavorInfo[tokenFlavor.flavorId] = tokenFlavor;
    }

    function _saveFlavorInfo(FlavorInfoV2 memory tokenFlavor) internal {
        _flavorInfo[tokenFlavor.flavorId].totalMinted = tokenFlavor.totalMinted;
    }

    function computeMaxSupply() external view returns (uint256) {
        return _computeMaxSupply();
    }

    function _computeMaxSupply() internal view returns (uint256) {
        uint256 maxSupply;

        for (uint256 idx = 0; idx < _flavorIds.length; idx++) {
            FlavorInfoV2 memory current = _flavorInfo[_flavorIds[idx]];
            maxSupply += current.maxSupply;
        }

        return maxSupply;
    }

    function _incrementMaxSupply(uint256 amount) internal {
        _maxSupply += amount;
    }

    function _decrementMaxSupply(uint256 amount) internal {
        require(amount > _maxSupply, 'Cannot decrement');

        _maxSupply -= amount;
    }

    function _getMaxSupply() internal view returns (uint256) {
        return _maxSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfoV2.sol';

/**
 * @title IFlavorInfoProviderV2
 * @author @NFTCulture
 * @dev Interface for Providing a product list definition.
 *
 * Note: This definition is compatible with the V2 version of Flavor Infos.
 */
interface IFlavorInfoProviderV2 is IFlavorInfoV2 {
    function provideFlavorInfos() external view returns (FlavorInfoV2[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IFlavorInfoV2
 * @author NFT Culture
 * @dev Interface for FlavorInfoV2 objects.
 *
 *  Bits Layout:
 *    256 bit slot #1
 *    - [0..63]    `flavorId`
 *    - [64..127]  `maxSupply`
 *    - [128..191] `totalMinted`
 *    - [192..255] `aux`
 *
 *    256 bit slot #2
 *    - [0..159]   `externalValidator`
 *    - [160..255] `price`
 *
 *    256 bit slot #3
 *    - [0..255] `uriFragment`
 *
 *  NOTE: Splitting out uriFragment and ipfsHash allows for the more gas efficient bytes32 uriFragment
 *  to be used if ipfsHash is included as part of Base URI.
 *
 *  URI should be built like: `${baseURI}${ipfsHash}${uriFragment}
 *    - Care should be taken to properly include '/' chars. Typically baseURI will have a trailing slash.
 *    - If ipfsHash is used, uriFragment should contain a leading '/'.
 *    - If ipfsHash is not used, uriFragment should not contain a leading '/'.
 */
interface IFlavorInfoV2 {
    struct FlavorInfoV2 {
        uint64 flavorId;
        uint64 maxSupply;
        uint64 totalMinted;
        uint64 aux; // Extra storage space that can be used however needed by the caller.
        address externalValidator; // Address of an external validator, for use cases such as making purchase of the product dependent on some other NFT project.
        uint96 price; // Price needs to be 96 bit. 64bit for value sets a cap at about 9.2 ETH (9.2e18 wei)
        bytes32 uriFragment; // Fragment to append to URI
        string ipfsHash; // IPFS Hash to append to URI
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from '@nftculture/nftc-contracts/contracts/utility/BooleanPacking.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title BasicPhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * The 'Basic' flavor only provides on/off controls for each phase, no pricing info or anything else.
 */
abstract contract BasicPhasedMintBase is Ownable {
    using BooleanPacking for uint256;

    // BooleanPacking used on _mintControlFlags
    uint256 internal _mintControlFlags;

    uint256 private immutable PUBLIC_MINT_PHASE;

    modifier isPublicMinting() {
        require(_mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(uint256 publicMintPhase) {
        PUBLIC_MINT_PHASE = publicMintPhase;
    }

    function _calculateMintingState(bool __publicMintingActive) internal view returns (uint256) {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(PUBLIC_MINT_PHASE, __publicMintingActive);

        // This does not set state, because state is held by the child classes.
        return tempControlFlags;
    }

    function isPublicMintingActive() external view returns (bool) {
        return _isPublicMintingActive();
    }

    function _isPublicMintingActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external view returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './BasicPhasedMintBase.sol';

/**
 * @title BasicPhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev 
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * The 'Basic' flavor only provides on/off controls for each phase, no pricing info or anything else.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
abstract contract BasicPhasedMintThree is Ownable, BasicPhasedMintBase {
    using BooleanPacking for uint256;

    uint256 private constant PHASE_ONE = 1;
    uint256 private constant PHASE_TWO = 2;

    modifier isPhaseOne() {
        require(_mintControlFlags.getBoolean(PHASE_ONE), 'Phase one stopped');
        _;
    }

    modifier isPhaseTwo() {
        require(_mintControlFlags.getBoolean(PHASE_TWO), 'Phase two stopped');
        _;
    }

    constructor() BasicPhasedMintBase(3) {}

    function setMintingState(
        bool __phaseOneActive,
        bool __phaseTwoActive,
        bool __publicMintingActive
    ) external onlyOwner {
        uint256 tempControlFlags = _calculateMintingState(__publicMintingActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_ONE, __phaseOneActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_TWO, __phaseTwoActive);

        _mintControlFlags = tempControlFlags;
    }

    function isPhaseOneActive() external view returns (bool) {
        return _isPhaseOneActive();
    }

    function _isPhaseOneActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_ONE);
    }

    function isPhaseTwoActive() external view returns (bool) {
        return _isPhaseTwoActive();
    }

    function _isPhaseTwoActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_TWO);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title ExpandablePhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * Expandable: An approach to ERC721 contracts that allows multiple subtypes of tokens.
 */
abstract contract ExpandablePhasedMintBase {
    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPublicMintPricePerNft(uint256 flavorId) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '../basic/BasicPhasedMintThree.sol';
import './ExpandablePhasedMintBase.sol';

/**
 * @title ExpandablePhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * Expandable: An approach to ERC721 contracts that allows multiple subtypes of tokens.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
abstract contract ExpandablePhasedMintThree is BasicPhasedMintThree, ExpandablePhasedMintBase {
    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPhaseOnePricePerNft(uint256 flavorId) external view virtual returns (uint256);

    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPhaseTwoPricePerNft(uint256 flavorId) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-contracts/contracts/utility/AuxHelper32.sol';

// NFTC Prerelease Contracts
import '../../whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '../../whitelisting/MerkleClaimList.sol';

error IndexedProofInvalid_PhaseOne();

/**
 * @title PhaseOneIsIndexed
 * @author @NiftyMike, NFT Culture
 * @dev Indexed Merkle Tree mint functionality for Phase One of a mint.
 */
abstract contract PhaseOneIsIndexed is MerkleLeaves, AuxHelper32 {
    using MerkleClaimList for MerkleClaimList.Root;

    MerkleClaimList.Root private _phaseOneRoot;

    constructor() {}

    /**
     * @dev Set the root of this merkle tree.
     */
    function _setPhaseOneRoot(bytes32 __root) internal {
        _phaseOneRoot._setRoot(__root);
    }

    function checkProof_PhaseOne(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextEntryIndex_PhaseOne(address wallet) external view returns (uint256) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseOnePurchases;
    }

    function getTokensPurchased_PhaseOne(address wallet) external view returns (uint32) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseOnePurchases;
    }

    function _getPackedPurchasesAs64(address wallet) internal view virtual returns (uint64);

    function _proofMintTokens_PhaseOne(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseOne();
        }

        _internalMintTokens(destination, count);
    }

    function _proofMintTokensOfFlavor_PhaseOne(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 flavorId,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseOne();
        }

        _internalMintTokens(destination, count, flavorId);
    }

    function _internalMintTokens(address destination, uint256 count) internal virtual;

    function _internalMintTokens(
        address destination,
        uint256 count,
        uint256 flavorId
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-contracts/contracts/utility/AuxHelper32.sol';

// NFTC Prerelease Contracts
import '../../whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '../../whitelisting/MerkleClaimList.sol';

error IndexedProofInvalid_PhaseTwo();

/**
 * @title PhaseTwoIsIndexed
 * @author @NiftyMike, NFT Culture
 * @dev Indexed Merkle Tree mint functionality for Phase Two of a mint.
 */
abstract contract PhaseTwoIsIndexed is MerkleLeaves, AuxHelper32 {
    using MerkleClaimList for MerkleClaimList.Root;

    MerkleClaimList.Root private _phaseTwoRoot;

    constructor() {}

    function _setPhaseTwoRoot(bytes32 __root) internal {
        _phaseTwoRoot._setRoot(__root);
    }

    function checkProof_PhaseTwo(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextEntryIndex_PhaseTwo(address wallet) external view returns (uint256) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseTwoPurchases;
    }

    function getTokensPurchased_PhaseTwo(address wallet) external view returns (uint32) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseTwoPurchases;
    }

    function _getPackedPurchasesAs64(address wallet) internal view virtual returns (uint64);

    function _proofMintTokens_PhaseTwo(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseTwo();
        }

        _internalMintTokens(destination, count);
    }

    function _proofMintTokensOfFlavor_PhaseTwo(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 flavorId,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseTwo();
        }

        _internalMintTokens(destination, count, flavorId);
    }

    function _internalMintTokens(address destination, uint256 count) internal virtual;

    function _internalMintTokens(
        address destination,
        uint256 count,
        uint256 flavorId
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @title PrivilegedMinter
 * @author @NiftyMike | @NFTCulture
 * @dev Control functions for supporting a privileged minter that mints to other, typically custodial wallets.
 */
abstract contract PrivilegedMinter is Context {
    address internal _privilegedMinter;

    modifier onlyPrivilegedMinter() {
        require(_privilegedMinter == _msgSender(), 'DM: caller is not delegate');
        _;
    }

    constructor(address __defaultPrivilegedMinter) {
        _privilegedMinter = __defaultPrivilegedMinter;
    }

    function _setPrivilegedMinter(address __newPrivilegedMinter) internal virtual {
        _privilegedMinter = __newPrivilegedMinter;
    }

    function getPrivilegedMinter() external view returns (address) {
        return _privilegedMinter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {MerkleRoot} from './MerkleRoot.sol';

/**
 * @title MerkleClaimList
 * @author @NiftyMike, NFT Culture
 * @dev Basic functionality for a MerkleTree that will be used as a "Claimlist"
 *
 * "Claimlist" - an approach for validating callers that is backed by a Merkle Tree.
 * Cheap to set the master claim, not that expensive to check the claim. Requires
 * off-chain generation of the Merkle Tree.
 *
 * This library allows you to declare a member variable like:
 * MerkleClaimList.Root private _claimRoot;
 *
 * The benefit of packaging this as a library, is that if you need multiple merkle trees in your
 * contract, you can declare multiple member variables using this library, and use them in similar fashion.
 *
 * see also: NFTC Labs' MerkleLeaves.sol, which is a companion abstract contract which contains helper
 * methods for generating leaves for the Merkle Tree.
 */
library MerkleClaimList {
    using MerkleRoot for bytes32;

    struct Root {
        // This variable should never be directly accessed by users of the library. See OZ comments in other libraries for more info.
        bytes32 _root;
    }

    /**
     * @dev Validate that a leaf is part of this merkle tree.
     */
    function _checkLeaf(
        Root storage root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal view returns (bool) {
        return root._root.check(proof, leaf);
    }

    /**
     * @dev Set the root of this merkle tree.
     */
    function _setRoot(Root storage root, bytes32 __root) internal {
        root._root = __root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title MerkleLeaves
 * @author @NiftyMike, NFT Culture
 * @dev Merkle Leaves for Merkle Trees - This is a companion contract to NFTC Labs' MerkleClaimList.sol library.
 * It provides leaf generation functions for both indexed and non-indexed merkle trees.
 * It also provides wrapper methods to expose the leaf generation functions to off-chain callers.
 *
 * Off-chain access is useful, because both the contract and the caller need to be able to generate the
 * leaves in a perfectly identical manner, so the generators are exposed to make it easier.
 */
abstract contract MerkleLeaves {
    /**
     * @notice External: generate a leaf for a wallet.
     *
     * @param wallet Address to hash.
     */
    function getLeafFor(address wallet) external pure returns (bytes32) {
        return _generateLeaf(wallet);
    }

    /**
     * @notice External: generate a leaf for a wallet and an embedded index value.
     *
     * @param wallet Address to hash.
     * @param index integer index to assign the leaf.
     */
    function getIndexedLeafFor(address wallet, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return _generateIndexedLeaf(wallet, index);
    }

    /**
     * @dev Generate a merkle leaf based only on a wallet address. This is useful when all users
     * represented in the tree are eligible for the exact same thing, such as one free mint.
     *
     * A tiered system can be supported by this approach, by making seperate merkle trees and
     * mint functions per tier, but that approach will become ungainly if you have to support more
     * than a few tiers.
     */
    function _generateLeaf(address wallet) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(wallet));
    }

    /**
     * @dev Generate a merkle leaf based on a wallet address and an index. This is useful when all
     * users represented in the tree are eligible for different amounts of something.
     */
    function _generateIndexedLeaf(address wallet, uint256 index)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, "_", index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
 * @title MerkleRoot
 * @author @NiftyMike, NFT Culture
 * @dev Companion library to OpenZeppelin's MerkleProof.
 * Allows you to abstract away merkle functionality a bit further, you now just need to
 * worry about dealing with your merkle root.
 *
 * Using this library allows you to treat bytes32 member variables as Merkle Roots, with a
 * slightly easier to use api then the OZ library.
 */
library MerkleRoot {
    using MerkleProof for bytes32[];

    function check(
        bytes32 root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bool) {
        return proof.verify(root, leaf);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

/**
 * @title ERC2981_NFTCExtended
 * @author @NiftyMike, NFT Culture
 * @dev A wrapper around ERC2981 which adds some common functionality.
 */
abstract contract ERC2981_NFTCExtended is ERC2981 {
    function setDefaultRoyalty(address newReceiver, uint96 newRoyalty) external {
        _isOwner();

        _setDefaultRoyalty(newReceiver, newRoyalty);
    }

    function _isOwner() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import './NFTCPaymentSplitterBase.sol';

/**
 * @title NFTCPaymentSplitter
 * @author @NiftyMike, NFT Culture
 * @dev NFTC's Implementation of a Payment Splitter
 *
 * Underlying is based on OpenZeppelin Contracts v4.8.0 (finance/PaymentSplitter.sol)
 */
abstract contract NFTCPaymentSplitter is NFTCPaymentSplitterBase {
    /**
     * @dev Overrides release() method, so that it can only be called by owner.
     * @notice Owner: Release funds to a specific address.
     *
     * @param account Payable address that will receive funds.
     */
    function release(address payable account) public override {
        _isOwner();

        _release(account);
    }

    /**
     * @dev Triggers a transfer to caller's address of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * @notice Sender: request payment.
     */
    function releaseToSelf() public {
        _release(payable(_msgSender()));
    }

    function _isOwner() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @title NFTCPaymentSplitterBase
 * @author @NiftyMike, NFT Culture
 * @dev An opinionated replacement of OZ's Payment Splitter.
 *
 * Notes:
 *  - Based on OZ Contracts v4.8.0 (finance/PaymentSplitter.sol)
 *  - ERC-20 token functionality removed to save gas.
 *  - Transferability of Payees, but only by Payee
 *  - Some require messages are shortened.
 *  - contract changed to abstract and release() functionality moved to internal method.
 *
 * IMPORTANT: changes to release() require higher level classes to expose release() in order
 * for funds to be withdrawn. This allows higher level classes to enforce better controls.
 */
abstract contract NFTCPaymentSplitterBase is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event PayeeTransferred(address oldOwner, address newOwner);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, 'PaymentSplitter: length mismatch');
        require(payees.length > 0, 'PaymentSplitter: no payees');

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        return _releasable(account);
    }

    function _releasable(address account) internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) internal {
        require(_shares[account] > 0, 'PaymentSplitter: no shares');

        uint256 payment = _releasable(account);

        require(payment != 0, 'PaymentSplitter: not due payment');

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), 'PaymentSplitter: zero address');
        require(shares_ > 0, 'PaymentSplitter: no shares');
        require(_shares[account] == 0, 'PaymentSplitter: payee has shares');

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Allows owner to transfer their shares to somebody else; it can only be called by of a share.
     * @notice Owner: Release funds to a specific address.
     *
     * @param newOwner Payable address which has no shares and will receive the shares of the current owner.
     */
    function transferPayee(address payable newOwner) public {
        require(newOwner != address(0), 'PaymentSplitter: zero address');
        require(_shares[_msgSender()] > 0, 'PaymentSplitter: no owned shares');
        require(_shares[newOwner] == 0, 'PaymentSplitter: payee has shares');

        _transferPayee(newOwner);
        emit PayeeTransferred(_msgSender(), newOwner);
    }

    function _transferPayee(address newOwner) private {
        if (_payees.length == 0) return;

        for (uint i = 0; i < _payees.length - 1; i++) {
            if (_payees[i] == _msgSender()) {
                _payees[i] = newOwner;
                _shares[newOwner] = _shares[_msgSender()];
                _shares[_msgSender()] = 0;
            }
        }
    }

    function release(address payable account) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import './ERC2981_NFTCExtended.sol';
import './NFTCPaymentSplitter.sol';

/**
 * @title ERC2981_NFTCExtended
 * @author @NiftyMike, NFT Culture
 * @dev One stop shop for Payment Splits and ERC2981 Royalty Definition.
 */
abstract contract NFTCSplitsAndRoyalties is NFTCPaymentSplitter, ERC2981_NFTCExtended {
    constructor(
        address[] memory __addresses,
        uint256[] memory __splits,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyBasisPoints
    ) NFTCPaymentSplitterBase(__addresses, __splits) {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyBasisPoints);
    }

    function _isOwner() internal view virtual override(NFTCPaymentSplitter, ERC2981_NFTCExtended);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelper32
 * @author @NiftyMike | NFT Culture
 * @dev Helper class for ERC721a Aux storage, using 32 bit ints.
 */
abstract contract AuxHelper32 {
    function _pack32(uint32 left32, uint32 right32) internal pure returns (uint64) {
        return (uint64(left32) << 32) | uint32(right32);
    }

    function _unpack32(uint64 aux) internal pure returns (uint32 left32, uint32 right32) {
        return (uint32(aux >> 32), uint32(aux));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title BooleanPacking
 * @author @NiftyMike, NFT Culture
 * @dev Credit to Zimri Leijen
 * See https://ethereum.stackexchange.com/a/92235
 */
library BooleanPacking {
    function getBoolean(uint256 _packedBools, uint256 _columnNumber)
        internal
        pure
        returns (bool)
    {
        uint256 flag = (_packedBools >> _columnNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(
        uint256 _packedBools,
        uint256 _columnNumber,
        bool _value
    ) internal pure returns (uint256) {
        if (_value) {
            _packedBools = _packedBools | (uint256(1) << _columnNumber);
            return _packedBools;
        } else {
            _packedBools = _packedBools & ~(uint256(1) << _columnNumber);
            return _packedBools;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
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
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
pragma solidity 0.8.17;

import './NFTC_Reference_ERC1155_GOERLI_ThreeBase.sol';
import './NFTC_Reference_ERC1155_GOERLI_ThreeSplitsAndRoyalties.sol';

/**
 * @title NFTC_Reference_ERC1155_GOERLI_Three
 * @author @NFTCulture
 * @dev NFTC Reference ERC1155 Implementation.
 */
contract NFTC_Reference_ERC1155_GOERLI_Three is
    NFTC_Reference_ERC1155_GOERLI_ThreeBase,
    NFTC_Reference_ERC1155_GOERLI_ThreeSplitsAndRoyalties
{
    constructor()
        NFTC_Reference_ERC1155_GOERLI_ThreeBase(
            'https://nftc-media.mypinata.cloud/ipfs/QmNaNCsufrof7s9xp7whbo8dq1hdYdjmjYfgKvGSFbg23f/{id}.json' // Dr3amLabs_Reference1155_Metadata_V1cb
        )
    {
        // Implementation version: v1.0.0

        // For goerli only, debug roots.
        _setMerkleRoots(0x0fbf76d248751f80ba28bfffc569ae6ae517b751f70cfa83cfb3de68a5bd9824, 0x5abf6f348d3a38ac6bec81a51134be4a24044996c279489dd9e67f84b0330815);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155_NFTCExtended_Expandable, ERC2981) returns (bool) {
        return ERC1155_NFTCExtended_Expandable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function _isOwner() internal view override {
        _checkOwner();
    }

    // For goerli only, withdraw by owner.
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _getInitialFlavors() internal pure override returns (FlavorInfoV2[] memory) {
        FlavorInfoV2[] memory initialFlavors = new FlavorInfoV2[](3);

        initialFlavors[0] = FlavorInfoV2(100100, 15, 0, 0, address(0),  .08 ether, 0, '');
        initialFlavors[1] = FlavorInfoV2(200100, 100, 0, 0, address(0), .05 ether, 0, '');
        initialFlavors[2] = FlavorInfoV2(300100, 0, 0, 0, address(0),   .02 ether, 0, '');

        return initialFlavors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/ERC1155_NFTCExtended_Expandable.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/expandable/ExpandablePhasedMintThree.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/PhaseOneIsIndexed.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/PhaseTwoIsIndexed.sol';
import '@nftculture/nftc-contracts-private/contracts/token/PrivilegedMinter.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title NFTC_Reference_ERC1155_GOERLI_ThreeBase
 * @author @NFTCulture
 * @dev ERC1155 Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase Three.
 */
abstract contract NFTC_Reference_ERC1155_GOERLI_ThreeBase is
    ERC1155_NFTCExtended_Expandable,
    ReentrancyGuard,
    ExpandablePhasedMintThree,
    PhaseOneIsIndexed,
    PhaseTwoIsIndexed,
    PrivilegedMinter
{
    bytes32 public constant PRODUCT_MANAGER_ROLE = keccak256('PRODUCT_MANAGER_ROLE');

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;
    uint256 private constant PHASE_ONE_BATCH_SIZE = 10;
    uint256 private constant PHASE_TWO_BATCH_SIZE = 10;
    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 10;

    address private constant CROSSMINT = address(0xdAb1a1854214684acE522439684a145E62505233);

    constructor(
        string memory __baseURI
    ) ERC1155_NFTCExtended_Expandable(__baseURI, true) ExpandablePhasedMintThree() PrivilegedMinter(CROSSMINT) {
        _grantRole(PRODUCT_MANAGER_ROLE, msg.sender);
    }

    function nftcContractDefinition() external pure returns (string memory) {
        // NFTC Contract Definition for front-end websites.
        return
            string(
                abi.encodePacked(
                    '{',
                    '"ncdVersion":1,', // NFTC Contract Definition version.
                    '"phases":3,', // # of mint phases?
                    '"type":"Expandable",', // do tokens have a type? [Static | Expandable]
                    '"openEdition":false', // is collection an open edition? [true | false]
                    '}'
                )
            );
    }

    function phaseOneBatchSize() external pure returns (uint256) {
        return PHASE_ONE_BATCH_SIZE;
    }

    function phaseTwoBatchSize() external pure returns (uint256) {
        return PHASE_TWO_BATCH_SIZE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return PUBLIC_MINT_BATCH_SIZE;
    }

    function getPhaseOnePricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
    }

    function getPhaseTwoPricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
    }

    function getPublicMintPricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
    }

    function setMerkleRoots(bytes32 __indexedRoot1, bytes32 __indexedRoot2) external onlyOwner {
        _setMerkleRoots(__indexedRoot1, __indexedRoot2);
    }

    function _setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) internal {
        if (__phaseOneRoot != 0) {
            _setPhaseOneRoot(__phaseOneRoot);
        }

        if (__phaseTwoRoot != 0) {
            _setPhaseTwoRoot(__phaseTwoRoot);
        }
    }

    function _getPackedPurchasesAs64(
        address //wallet
    ) internal view virtual override(PhaseOneIsIndexed, PhaseTwoIsIndexed) returns (uint64) {
        return 0;
    }

    /**
     * @notice ProductManager: reserve tokens for a friend.
     *
     * @param friend address to send tokens to.
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function premintTokens(address friend, uint256 count, uint256 flavorId) external {
        if (!hasRole(PRODUCT_MANAGER_ROLE, msg.sender)) revert InvalidAccess();

        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfoV2 memory updatedFlavor = _canMint(count, flavorId, false, 0);
        _saveFlavorInfo(updatedFlavor);

        _internalMintTokensOfFlavor(friend, count, flavorId);
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * @param friends addresses to send tokens to.
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function reserveTokens(address[] memory friends, uint256 count, uint256 flavorId) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfoV2 memory updatedFlavor = _canMint(count * friends.length, flavorId, false, 0);
        _saveFlavorInfo(updatedFlavor);

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokensOfFlavor(friends[idx], count, flavorId);
        }
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function publicMintTokens(uint256 count, uint256 flavorId) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfoV2 memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveFlavorInfo(updatedFlavor);

        _internalMintTokensOfFlavor(msg.sender, count, flavorId);
    }

    /**
     * @notice Same as publicMintTokens(), but with a "to" for purchasing / custodial wallet platforms.
     *
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     * @param to address where the new token should be sent.
     */
    function publicMintTokensTo(
        uint256 count,
        uint256 flavorId,
        address to
    ) external payable nonReentrant isPublicMinting onlyPrivilegedMinter {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfoV2 memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveFlavorInfo(updatedFlavor);

        _internalMintTokensOfFlavor(to, count, flavorId);
    }

    function _internalMintTokens(
        address minter,
        uint256 count
    ) internal override(PhaseOneIsIndexed, PhaseTwoIsIndexed) {
        // Do nothing
    }

    function _internalMintTokens(
        address minter,
        uint256 count,
        uint256 flavorId
    ) internal override(PhaseOneIsIndexed, PhaseTwoIsIndexed) {
        _internalMintTokensOfFlavor(minter, count, flavorId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import '@nftculture/nftc-contracts/contracts/financial/NFTCSplitsAndRoyalties.sol';

abstract contract NFTC_Reference_ERC1155_GOERLI_ThreeSplitsAndRoyalties is NFTCSplitsAndRoyalties {
    address[] internal addresses = [
        0x05Ed4cf991c4ed7606930AB54dDbF27836C1f590 // Goerli
    ];

    uint256[] internal splits = [100]; // Goerli

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 750;

    constructor() NFTCSplitsAndRoyalties(addresses, splits, address(this), DEFAULT_ROYALTY_BASIS_POINTS) {
        // Nothing to do.
    }
}