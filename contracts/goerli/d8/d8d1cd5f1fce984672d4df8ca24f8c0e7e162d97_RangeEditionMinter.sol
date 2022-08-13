// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import "./MintControllerBase.sol";

/*
 * @dev Minter class for range edition sales.
 */
contract RangeEditionMinter is MintControllerBase {
    // ================================
    // CUSTOM ERRORS
    // ================================

    /**
     * The following condition must hold: `startTime` < `closingTime` < `endTime`.
     */
    error InvalidTimeRange(uint32 startTime, uint32 closingTime, uint32 endTime);

    /**
     * The following condition must hold: `maxMintableLower` < `maxMintableUpper`.
     */
    error InvalidMaxMintableRange(uint32 maxMintableLower, uint32 maxMintableUpper);

    // ================================
    // EVENTS
    // ================================

    // prettier-ignore
    event RangeEditionMintCreated(
        address indexed edition,
        uint256 indexed mintId, 
        uint256 price,
        uint32 startTime,
        uint32 closingTime,
        uint32 endTime,
        uint32 maxMintableLower,
        uint32 maxMintableUpper
    );

    event TimeRangeSet(
        address indexed edition,
        uint256 indexed mintId,
        uint32 startTime,
        uint32 closingTime,
        uint32 endTime
    );

    event MaxMintableRangeSet(
        address indexed edition,
        uint256 indexed mintId,
        uint32 maxMintableLower,
        uint32 maxMintableUpper
    );

    // ================================
    // STRUCTS
    // ================================

    struct EditionMintData {
        // The price at which each token will be sold, in ETH.
        uint256 price;
        // Start timestamp of sale (in seconds since unix epoch).
        uint32 startTime;
        // The timestamp (in seconds since unix epoch) after which the
        // max amount of tokens mintable will drop from
        // `maxMintableUpper` to `maxMintableLower`.
        uint32 closingTime;
        // End timestamp of sale (in seconds since unix epoch).
        uint32 endTime;
        // The total number of tokens minted. Includes permissioned mints.
        uint32 totalMinted;
        // The lower limit of the maximum number of tokens that can be minted.
        uint32 maxMintableLower;
        // The upper limit of the maximum number of tokens that can be minted.
        uint32 maxMintableUpper;
    }

    // ================================
    // STORAGE
    // ================================

    mapping(address => mapping(uint256 => EditionMintData)) internal _editionMintData;

    // ================================
    // CREATE AND DELETE
    // ================================

    /*
     * @dev Initializes the configuration for an edition mint.
     * @param edition Address of the song edition contract we are minting for.
     * @param price Sale price in ETH for minting a single token in `edition`.
     * @param startTime Start timestamp of sale (in seconds since unix epoch).
     * @param closingTime The timestamp (in seconds since unix epoch) after which the
     * max amount of tokens mintable will drop from
     * `maxMintableUpper` to `maxMintableLower`.
     * @param endTime End timestamp of sale (in seconds since unix epoch).
     * @param maxMintableLower The lower limit of the maximum number of tokens that can be minted.
     * @param maxMintableUpper The upper limit of the maximum number of tokens that can be minted.
     */
    function createEditionMint(
        address edition,
        uint256 price,
        uint32 startTime,
        uint32 closingTime,
        uint32 endTime,
        uint32 maxMintableLower,
        uint32 maxMintableUpper
    ) public returns (uint256 mintId) {
        mintId = _createEditionMintController(edition);

        EditionMintData storage data = _editionMintData[edition][mintId];
        data.price = price;
        data.startTime = startTime;
        data.closingTime = closingTime;
        data.endTime = endTime;
        data.maxMintableLower = maxMintableLower;
        data.maxMintableUpper = maxMintableUpper;

        if (!(data.startTime < data.closingTime && data.closingTime < data.endTime))
            revert InvalidTimeRange(data.startTime, data.closingTime, data.endTime);

        if (!(data.maxMintableLower < data.maxMintableUpper))
            revert InvalidMaxMintableRange(data.maxMintableLower, data.maxMintableUpper);

        // prettier-ignore
        emit RangeEditionMintCreated(
            edition,
            mintId, 
            price,
            startTime,
            closingTime,
            endTime,
            maxMintableLower,
            maxMintableUpper
        );
    }

    /*
     * @dev Deletes the configuration for an edition mint.
     * @param edition Address of the song edition contract we are minting for.
     */
    function deleteEditionMint(address edition, uint256 mintId) public {
        _deleteEditionMintController(edition, mintId);
        delete _editionMintData[edition][mintId];
    }

    /**
     * @dev Returns the `EditionMintData` for `edition.
     * @param edition Address of the song edition contract we are minting for.
     */
    function editionMintData(address edition, uint256 mintId) public view returns (EditionMintData memory) {
        return _editionMintData[edition][mintId];
    }

    // ================================
    // MINT
    // ================================

    /*
     * @dev Mints tokens for a given edition.
     * @param edition Address of the song edition contract we are minting for.
     * @param quantity Token quantity to mint in song `edition`.
     */
    function mint(
        address edition,
        uint256 mintId,
        uint32 quantity
    ) public payable {
        EditionMintData storage data = _editionMintData[edition][mintId];

        _requireMintOpen(data.startTime, data.endTime);

        uint32 maxMintable;
        if (block.timestamp < data.closingTime) {
            maxMintable = data.maxMintableUpper;
        } else {
            maxMintable = data.maxMintableLower;
        }
        // Increase `totalMinted` by `quantity`.
        // Require that the increased value does not exceed `maxMintable`.
        uint32 nextTotalMinted = data.totalMinted + quantity;
        _requireNotSoldOut(nextTotalMinted, maxMintable);
        data.totalMinted = nextTotalMinted;

        _mint(edition, mintId, msg.sender, quantity, quantity * data.price);
    }

    // ================================
    // SETTER FUNCTIONS
    // ================================

    /*
     * @dev Sets the time range.
     * @param edition Address of the song edition contract we are minting for.
     * @param startTime Start timestamp of sale (in seconds since unix epoch).
     * @param closingTime The timestamp (in seconds since unix epoch) after which the
     * max amount of tokens mintable will drop from
     * `maxMintableUpper` to `maxMintableLower`.
     * @param endTime End timestamp of sale (in seconds since unix epoch).
     */
    function setTimeRange(
        address edition,
        uint256 mintId,
        uint32 startTime,
        uint32 closingTime,
        uint32 endTime
    ) public onlyEditionMintController(edition, mintId) {
        EditionMintData storage data = _editionMintData[edition][mintId];
        data.startTime = startTime;
        data.closingTime = closingTime;
        data.endTime = endTime;

        if (!(data.startTime < data.closingTime && data.closingTime < data.endTime))
            revert InvalidTimeRange(data.startTime, data.closingTime, data.endTime);

        emit TimeRangeSet(edition, mintId, startTime, closingTime, endTime);
    }

    /*
     * @dev Sets the max mintable range.
     * @param edition Address of the song edition contract we are minting for.
     * @param maxMintableLower The lower limit of the maximum number of tokens that can be minted.
     * @param maxMintableUpper The upper limit of the maximum number of tokens that can be minted.
     */
    function setMaxMintableRange(
        address edition,
        uint256 mintId,
        uint32 maxMintableLower,
        uint32 maxMintableUpper
    ) public onlyEditionMintController(edition, mintId) {
        EditionMintData storage data = _editionMintData[edition][mintId];
        data.maxMintableLower = maxMintableLower;
        data.maxMintableUpper = maxMintableUpper;

        if (!(data.maxMintableLower < data.maxMintableUpper))
            revert InvalidMaxMintableRange(data.maxMintableLower, data.maxMintableUpper);

        emit MaxMintableRangeSet(edition, mintId, maxMintableLower, maxMintableUpper);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../../SoundEdition/ISoundEditionV1.sol";

/**
 * @title Mint Controller Base
 * @dev The `MintControllerBase` class maintains a central storage record of mint controllers.
 */
abstract contract MintControllerBase {
    // ================================
    // CUSTOM ERRORS
    // ================================

    /**
     * The caller must be the the controller of this edition to perform this action.
     */
    error MintControllerUnauthorized();

    /**
     * There is no controller assigned to this edition.
     */
    error MintControllerNotFound();

    /**
     * A mint controller is already assigned to this edition.
     */
    error MintControllerAlreadyExists(address controller);

    /**
     * The `paid` Ether value must be equal to the `required` Ether value.
     */
    error WrongEtherValue(uint256 paid, uint256 required);

    /**
     * The total minted cannot exceed `maxMintable`.
     */
    error SoldOut(uint32 maxMintable);

    /**
     * The current block timestamp must be between `startTime` and `endTime`, inclusive.
     */
    error MintNotOpen(uint256 blockTimestamp, uint32 startTime, uint32 endTime);

    /**
     * The mint is paused.
     */
    error MintPaused();

    /**
     * The caller must be the owner of the edition contract.
     */
    error CallerNotEditionOwner();

    /// @dev Unauthorized caller
    error Unauthorized();

    // ================================
    // EVENTS
    // ================================

    /**
     * @notice Emitted when the mint `controller` for `edition` renounces their own access.
     */
    event MintControllerAccessRenounced(address indexed edition, uint256 indexed mintId, address indexed controller);

    /**
     * @notice Emitted when the mint `controller` for `edition` is updated.
     */
    event MintControllerSet(address indexed edition, uint256 indexed mintId, address indexed controller);

    /**
     * @notice Emitted when the `paused` status of `edition` is updated.
     */
    event MintPausedSet(address indexed edition, uint256 indexed mintId, bool indexed paused);

    // ================================
    // STRUCTS
    // ================================

    struct BaseData {
        address controller;
        bool mintPaused;
    }

    // ================================
    // STORAGE
    // ================================

    /**
     * @dev Maps an edition to the its next mint ID.
     */
    mapping(address => uint256) private _nextMintIds;

    /**
     * @dev Maps an edition and the mint ID to a controller.
     */
    mapping(address => mapping(uint256 => BaseData)) private _baseData;

    // ================================
    // MINT CONTROLLER FUNCTIONS
    // ================================

    /**
     * @dev Restricts the function to be only callable by the controller of `edition`.
     */
    modifier onlyEditionMintController(address edition, uint256 mintId) virtual {
        BaseData storage data = _baseData[edition][mintId];

        if (data.controller == address(0)) revert MintControllerNotFound();
        if (msg.sender != data.controller) revert MintControllerUnauthorized();

        _;
    }

    /**
     * @dev Assigns the current caller as the controller to `edition`.
     * Calling conditions:
     * - The `edition` must not have a controller.
     */
    function _createEditionMintController(address edition) internal returns (uint256 mintId) {
        if (!_callerIsEditionOwner(edition)) revert CallerNotEditionOwner();

        mintId = _nextMintIds[edition];

        BaseData storage data = _baseData[edition][mintId];
        if (data.controller != address(0)) revert MintControllerAlreadyExists(data.controller);
        data.controller = msg.sender;

        _nextMintIds[edition] += 1;

        emit MintControllerSet(edition, mintId, msg.sender);
    }

    /**
     * @dev Returns whether the caller is the owner of `edition`.
     */
    function _callerIsEditionOwner(address edition) private returns (bool result) {
        // To avoid defining an interface just to call `owner()`.
        // And Solidity does not have try catch for plain old `call`.
        assembly {
            // Store the 4-byte function selector of `owner()` into scratch space.
            mstore(0x00, 0x8da5cb5b)
            // The `call` must be placed as the last argument of `and`,
            // as the arguments are evaluated right to left.
            result := and(
                and(
                    // Whether the returned address equals `msg.sender`.
                    eq(mload(0x00), caller()),
                    // Whether at least a word has been returned.
                    gt(returndatasize(), 31)
                ),
                call(
                    gas(), // Remaining gas.
                    edition, // The `edition` address.
                    0, // Send 0 Ether.
                    0x1c, // Offset of the selector in the memory.
                    0x04, // Size of the selector (4 bytes).
                    0x00, // Offset of the return data.
                    0x20 // Size of the return data (1 32-byte word).
                )
            )
        }
    }

    /**
     * @dev Convenience function for deleting a mint controller.
     * Equivalent to `setEditionMintController(edition, address(0))`.
     */
    function _deleteEditionMintController(address edition, uint256 mintId) internal {
        setEditionMintController(edition, mintId, address(0));
    }

    /**
     * @dev Returns the mint controller for `edition`.
     */
    function editionMintController(address edition, uint256 mintId) public view returns (address) {
        return _baseData[edition][mintId].controller;
    }

    /**
     * @dev Sets the new `controller` for `edition`.
     * Calling conditions:
     * - The caller must be the current controller for `edition`.
     */
    function setEditionMintController(
        address edition,
        uint256 mintId,
        address controller
    ) public virtual onlyEditionMintController(edition, mintId) {
        _baseData[edition][mintId].controller = controller;
        emit MintControllerSet(edition, mintId, controller);
    }

    /**
     * @dev Sets the `paused` status for `edition`.
     * Calling conditions:
     * - The caller must be the current controller for `edition`.
     */
    function setEditionMintPaused(
        address edition,
        uint256 mintId,
        bool paused
    ) public virtual onlyEditionMintController(edition, mintId) {
        _baseData[edition][mintId].mintPaused = paused;
        emit MintPausedSet(edition, mintId, paused);
    }

    /**
     * @dev Returns the next mint ID for `edition`.
     */
    function nextMintId(address edition) public view returns (uint256) {
        return _nextMintIds[edition];
    }

    // ================================
    // INTERNAL HELPER FUNCTIONS
    // ================================

    /**
     * @dev Mints `quantity` of `edition` to `to` with a required payment of `requiredEtherValue`.
     */
    function _mint(
        address edition,
        uint256 mintId,
        address to,
        uint32 quantity,
        uint256 requiredEtherValue
    ) internal {
        if (msg.value != requiredEtherValue) revert WrongEtherValue(msg.value, requiredEtherValue);
        if (_baseData[edition][mintId].mintPaused) revert MintPaused();
        ISoundEditionV1(edition).mint{ value: msg.value }(to, quantity);
    }

    /**
     * @dev Requires that `startTime <= block.timestamp <= endTime`.
     */
    function _requireMintOpen(uint32 startTime, uint32 endTime) internal view {
        if (block.timestamp < startTime) revert MintNotOpen(block.timestamp, startTime, endTime);
        if (block.timestamp > endTime) revert MintNotOpen(block.timestamp, startTime, endTime);
    }

    /**
     * @dev Requires that `totalMinted <= maxMintable`.
     */
    function _requireNotSoldOut(uint32 totalMinted, uint32 maxMintable) internal pure {
        if (totalMinted > maxMintable) revert SoldOut(maxMintable);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import "chiru-labs/ERC721A-Upgradeable/interfaces/IERC721AUpgradeable.sol";
import "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "../modules/Metadata/IMetadataModule.sol";

/*
                 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒                
               ▒███████████████████████████████████████████████████████████               
               ▒███████████████████████████████████████████████████████████               
 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒ 
 █████████████████████████████▓              ████████████████████████████████████████████ 
 █████████████████████████████▓              ████████████████████████████████████████████ 
 █████████████████████████████▓               ▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████████████████ 
 █████████████████████████████▓                            ▒█████████████████████████████ 
 █████████████████████████████▓                             ▒████████████████████████████ 
 █████████████████████████████████████████████████████████▓                              
 ███████████████████████████████████████████████████████████                              
 ███████████████████████████████████████████████████████████▒                             
                              ███████████████████████████████████████████████████████████▒
                              ▓██████████████████████████████████████████████████████████▒
                               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████▒
 █████████████████████████████                             ▒█████████████████████████████▒
 ██████████████████████████████                            ▒█████████████████████████████▒
 ██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒              ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒ 
               ▓██████████████████████████████████████████████████████████▒               
               ▓██████████████████████████████████████████████████████████                
*/

/**
 * @title ISoundEditionV1
 * @author Sound.xyz
 */
interface ISoundEditionV1 is IERC721AUpgradeable, IERC2981Upgradeable {
    /// Getter for minter role hash
    function MINTER_ROLE() external returns (bytes32);

    /// Getter for admin role hash
    function ADMIN_ROLE() external returns (bytes32);

    /**
     * @dev Initializes the contract
     * @param owner Owner of contract (artist)
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param metadataModule Address of metadata module, address(0x00) if not used
     * @param baseURI Base URI
     * @param contractURI Contract URI for OpenSea storefront
     * @param masterMaxMintable The maximum amount of tokens that can be minted for this edition.
     * @param randomnessLockedAfterMinted Token supply after which randomness gets locked
     * @param randomnessLockedTimestamp Timestamp after which randomness gets locked
     */
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        IMetadataModule metadataModule,
        string memory baseURI,
        string memory contractURI,
        uint32 masterMaxMintable,
        uint32 randomnessLockedAfterMinted,
        uint32 randomnessLockedTimestamp
    ) external;

    /**
     * @dev Mints `quantity` tokens to addrress `to`
     * Each token will be assigned a token ID that is consecutively increasing.
     * The caller must have the `MINTERROLE`, which can be granted via
     * {grantRole}. Multiple minters, such as different minter contracts,
     * can be authorized simultaneously.
     * @param to Address to mint to
     * @param quantity Number of tokens to mint
     */
    function mint(address to, uint256 quantity) external payable;

    /**
     * @dev Informs other contracts which interfaces this contract supports.
     * https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface id to check.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC721AUpgradeable, IERC165Upgradeable)
        returns (bool);

    /**
     *  @dev Sets metadata module
     */
    function setMetadataModule(IMetadataModule metadataModule) external;

    /**
     *  @dev Sets global base URI
     */
    function setBaseURI(string memory baseURI) external;

    /**
     *   @dev Sets contract URI
     */
    function setContractURI(string memory _contractURI) external;

    /**
     *   @dev Freezes metadata by preventing any more changes to base URI
     */
    function freezeMetadata() external;

    /**
     * @dev sets randomnessLockedAfterMinted in case of insufficient sales, to finalize goldenEgg
     */
    function setMintRandomnessLock(uint32 randomnessLockedAfterMinted) external;

    /**
     * @dev sets randomnessLockedTimestamp
     */
    function setRandomnessLockedTimestamp(uint32 randomnessLockedTimestamp_) external;

    /// @dev Returns the base token URI for the collection
    function baseURI() external view returns (string memory);

    /// @dev Returns the total amount of tokens minted in the contract
    function totalMinted() external view returns (uint256);

    function randomnessLockedAfterMinted() external view returns (uint32);

    function randomnessLockedTimestamp() external view returns (uint32);

    function mintRandomness() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721AUpgradeable.sol';

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

/*
                 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒                
               ▒███████████████████████████████████████████████████████████               
               ▒███████████████████████████████████████████████████████████               
 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒ 
 █████████████████████████████▓              ████████████████████████████████████████████ 
 █████████████████████████████▓              ████████████████████████████████████████████ 
 █████████████████████████████▓               ▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████████████████ 
 █████████████████████████████▓                            ▒█████████████████████████████ 
 █████████████████████████████▓                             ▒████████████████████████████ 
 █████████████████████████████████████████████████████████▓                              
 ███████████████████████████████████████████████████████████                              
 ███████████████████████████████████████████████████████████▒                             
                              ███████████████████████████████████████████████████████████▒
                              ▓██████████████████████████████████████████████████████████▒
                               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████▒
 █████████████████████████████                             ▒█████████████████████████████▒
 ██████████████████████████████                            ▒█████████████████████████████▒
 ██████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒              ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ████████████████████████████████████████████▒             ▒█████████████████████████████▒
 ▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒ 
               ▓██████████████████████████████████████████████████████████▒               
               ▓██████████████████████████████████████████████████████████                
*/

/**
 * @title IMetadataModule
 * @author Sound.xyz
 */
interface IMetadataModule {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable {
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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
interface IERC165Upgradeable {
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