// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15; // code below expects that integer overflows will revert
/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░██░░░░░██░░██████░░██░░██░░██████░░░░██████░░█████░░░██████░░
░░██░░░░░██░░██░░░░░░██░░██░░░░██░░░░░░██░░██░░██░░██░░░░██░░░░
░░██░░░░░██░░██░███░░██████░░░░██░░░░░░██████░░█████░░░░░██░░░░
░░██░░░░░██░░██░░██░░██░░██░░░░██░░░░░░██░░██░░██░░██░░░░██░░░░
░░█████░░██░░██████░░██░░██░░░░██░░░██░██░░██░░██░░██░░░░██░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/token/ERC721/ERC721.sol";
import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/utils/cryptography/MerkleProof.sol";
import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/utils/Strings.sol";
import "./ThreeChiefOfficersWithRoyalties.sol";
import "./Packing.sol";

/// @title  Light 💡
/// @notice This contract has reusable functions and is meant to be deployed multiple times to accommodate different
///         Light collections.
/// @author William Entriken
contract Light is ERC721, ThreeChiefOfficersWithRoyalties {
    /// @param startTime      effective beginning time for phase to take effect
    /// @param ethPrice       price in Wei for the sale
    /// @param accessListRoot Merkle root for addresses and quantities on an access list, or zero to indicate public
    ///                       availability; reusing an access list will continue depleting from that list
    struct DropPhase {
        uint64 startTime;
        uint128 ethPrice;
        bytes32 accessListRoot;
    }

    /// @param quantity     How many tokens are included in this drop
    /// @param passwordHash A secret hash known by the contract owner which is used to end the drop, or zero to indicate
    ///                     no randomness in this drop
    struct Drop {
        uint32 quantityForSale;
        uint32 quantitySold;
        uint32 quantityFrozenMetadata;
        string tokenURIBase; // final URI will add a token number to the end
        DropPhase[] phases; // Must be in ascending-time order
        bytes32 passwordHash; // A non-zero value indicates this drop's randomness is still accumulating
        uint256 accumulatedRandomness; // Beware, randomness on-chain is a game and can always be hacked to some extent
        string unrevealedTokenURIOverride; // If set, this will apply to the drop, otherwise the general URI will apply
    }

    /// @notice Metadata is no longer changeable by anyone
    /// @param  value   The metadata URI
    /// @param  tokenID Which token is set
    event PermanentURI(string value, uint256 indexed tokenID);

    uint256 immutable MAX_DROP_SIZE = 1000000; // Must fit into size of tokenIDInDrop

    /// @notice Listing of all drops
    mapping(uint64 => Drop) public drops;

    mapping(bytes32 => mapping(address => uint96)) public quantityMinted;

    /// @notice The URI to show for tokens that are not revealed yet
    string public unrevealedTokenURI;

    /// @notice Initializes the contract
    /// @param  name                     Name of the contract
    /// @param  symbol                   Symbol of the contract
    /// @param  unrevealedTokenURI_      URI of tokens that are randomized, before randomization is done
    /// @param  newChiefFinancialOfficer Address that will sale proceeds and is indicated to receive royalties
    constructor(
        string memory name,
        string memory symbol,
        string memory unrevealedTokenURI_,
        address payable newChiefFinancialOfficer,
        uint256 newRoyaltyFraction
    ) ERC721(name, symbol) ThreeChiefOfficersWithRoyalties(newChiefFinancialOfficer, newRoyaltyFraction) {
        unrevealedTokenURI = unrevealedTokenURI_;
    }

    /// @notice Opens a new drop for preparation by the contract owner
    /// @param  dropID          The identifier, or batch number, for the drop
    /// @param  quantityForSale How many tokens are included in this drop
    /// @param  tokenURIBase    A prefix to build each token's URI from
    /// @param  passwordHash    A secret hash known by the contract owner which is used to end the drop, or zero to
    ///                         indicate no randomness in this drop
    function prepareDrop(
        uint64 dropID,
        uint32 quantityForSale,
        string calldata tokenURIBase,
        bytes32 passwordHash
    ) external onlyOperatingOfficer {
        require(quantityForSale > 0, "Light: quantity may not be zero");
        require(quantityForSale <= MAX_DROP_SIZE, "Light: drop is too large");
        require(drops[dropID].quantityForSale == 0, "Light: This drop was already prepared");
        require(bytes(tokenURIBase).length > 0, "Light: missing URI base");
        Drop storage drop = drops[dropID];
        drop.quantityForSale = quantityForSale;
        drop.tokenURIBase = tokenURIBase;
        drop.passwordHash = passwordHash;
        drop.accumulatedRandomness = uint256(passwordHash);
    }

    /// @notice Ends a drop before any were sold
    /// @param  dropID The identifier, or batch number, for the drop
    function abortDrop(uint64 dropID) external onlyOperatingOfficer {
        require(drops[dropID].quantitySold == 0, "Light: this drop has already started selling");
        delete (drops[dropID]);
    }

    /// @notice Schedules sales phases for a drop, replacing any previously set phases; reusing an access list will
    ///         continue depleting from that list; if you don't want this, make any change to the access list
    /// @dev    This function will fail unless all URIs have been loaded for the drop.
    /// @param  dropID     The identifier, or batch number, for the drop
    /// @param  dropPhases Drop phases for the sale (must be in time-sequential order)
    function setDropPhases(uint64 dropID, DropPhase[] calldata dropPhases) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.quantityForSale > 0, "Light: this drop has not been prepared");
        delete drop.phases;
        for (uint256 index = 0; index < dropPhases.length; index++) {
            drop.phases.push(dropPhases[index]);
        }
    }

    /// @notice Mints a quantity of tokens, the related tokenURI is unknown until finalized
    /// @dev    This reverts unless there is randomness in this drop.
    /// @param  dropID             The identifier, or batch number, for the drop
    /// @param  quantity           How many tokens to purchase
    /// @param  accessListProof    A Merkle proof demonstrating that the message sender is on the access list,
    ///                            or zero if publicly available
    /// @param  accessListQuantity The amount of tokens this access list allows you to mint
    function mintRandom(
        uint64 dropID,
        uint64 quantity,
        bytes32[] calldata accessListProof,
        uint96 accessListQuantity
    ) external payable {
        Drop storage drop = drops[dropID];
        require(quantity > 0, "Light: missing purchase quantity");
        require(quantity + drop.quantitySold <= drop.quantityForSale, "Light: not enough left for sale");
        require(drop.accumulatedRandomness != 0, "Light: no randomness in this drop, use mintChosen instead");

        DropPhase memory dropPhase = _getEffectivePhase(drop);
        require(msg.value >= dropPhase.ethPrice * quantity, "Light: not enough Ether paid");

        if (dropPhase.accessListRoot != bytes32(0)) {
            _requireValidMerkleProof(dropPhase.accessListRoot, accessListProof, accessListQuantity);
            require(
                quantityMinted[dropPhase.accessListRoot][msg.sender] + quantity <= accessListQuantity,
                "Light: exceeded access list limit"
            );
        }

        _addEntropyBit(dropID, uint256(blockhash(block.number - 1)));

        if (dropPhase.accessListRoot != bytes32(0)) {
            quantityMinted[dropPhase.accessListRoot][msg.sender] += quantity;
        }

        for (uint256 mintCounter = 0; mintCounter < quantity; mintCounter++) {
            _mint(msg.sender, _assembleTokenID(dropID, drop.quantitySold));
            drop.quantitySold++;
        }
    }

    /// @notice Mints a selected set of tokens
    /// @dev    This reverts if there is randomness in this drop.
    /// @param  dropID             The identifier, or batch number, for the drop
    /// @param  tokenIDsInDrop     Which tokens to purchase
    /// @param  accessListProof    A Merkle proof demonstrating that the message sender is on the access list,
    ///                            or zero if publicly available
    /// @param  accessListQuantity The amount of tokens this access list allows you to mint
    function mintChosen(
        uint64 dropID,
        uint32[] calldata tokenIDsInDrop,
        bytes32[] calldata accessListProof,
        uint96 accessListQuantity
    ) external payable {
        Drop storage drop = drops[dropID];
        require(tokenIDsInDrop.length > 0, "Light: missing tokens to purchase");
        require(tokenIDsInDrop.length + drop.quantitySold <= drop.quantityForSale, "Light: not enough left for sale");
        require(tokenIDsInDrop.length < type(uint64).max);
        require(drop.accumulatedRandomness == 0, "Light: this drop uses randomness, use mintRandom instead");

        DropPhase memory dropPhase = _getEffectivePhase(drop);
        require(msg.value >= dropPhase.ethPrice * tokenIDsInDrop.length, "Light: not enough Ether paid");

        if (dropPhase.accessListRoot != bytes32(0)) {
            _requireValidMerkleProof(dropPhase.accessListRoot, accessListProof, accessListQuantity);
            require(
                quantityMinted[dropPhase.accessListRoot][msg.sender] + tokenIDsInDrop.length <= accessListQuantity,
                "Light: exceeded access list limit"
            );
        }

        drop.quantitySold += uint32(tokenIDsInDrop.length);

        if (dropPhase.accessListRoot != bytes32(0)) {
            quantityMinted[dropPhase.accessListRoot][msg.sender] += uint96(tokenIDsInDrop.length);
        }

        for (uint256 index = 0; index < tokenIDsInDrop.length; index++) {
            require(tokenIDsInDrop[index] < drop.quantityForSale, "Light: invalid token ID");
            _mint(msg.sender, _assembleTokenID(dropID, tokenIDsInDrop[index]));
        }
    }

    /// @notice Ends the sale and assigns any random tokens for a random drop
    /// @dev    Randomness is used from the owner's randomization secret as well as each buyer.
    /// @param  dropID   The identifier, or batch number, for the drop
    /// @param  password The secret of the hash originally used to prepare the drop, or zero if no randomness in this
    ///                  drop
    function finalizeRandomDrop(uint64 dropID, string calldata password) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.passwordHash != bytes32(0), "Light: this drop does not have a password (anymore)");
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not completed selling");
        require(keccak256(abi.encode(password)) == drop.passwordHash, "Light: wrong secret");
        _addEntropyBit(dropID, bytes(password).length);
        drop.passwordHash = bytes32(0);
    }

    /// @notice Ends the sale and assigns any random tokens for a random drop, only use this if operating officer
    ///         forgot the password and accepts the shame for such
    /// @dev    Randomness is used from the owner's randomization secret as well as each buyer.
    /// @param  dropID The identifier, or batch number, for the drop
    function finalizeRandomDropAndIForgotThePassword(uint64 dropID) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.passwordHash != bytes32(0), "Light: this drop does not have a password (anymore)");
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not completed selling");
        _addEntropyBit(dropID, uint256(blockhash(block.number - 1)));
        drop.passwordHash = bytes32(0);
    }

    /// @notice After a drop is sold out, indicate that metadata is no longer changeable by anyone
    /// @param  dropID           The identifier, or batch number, for the drop
    /// @param  quantityToFreeze How many remaining tokens to indicate as frozen (up to this many)
    function freezeMetadataForDrop(uint64 dropID, uint256 quantityToFreeze) external {
        Drop storage drop = drops[dropID];
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not sold out yet");
        require(drop.passwordHash == bytes32(0), "Light: this random drop has not been finalized yet");
        require(drop.quantityFrozenMetadata < drop.quantityForSale, "Light: all metadata is already frozen");
        while (quantityToFreeze > 0 && drop.quantityFrozenMetadata < drop.quantityForSale) {
            uint256 tokenID = _assembleTokenID(dropID, drop.quantityFrozenMetadata);
            emit PermanentURI(tokenURI(tokenID), tokenID);
            drop.quantityFrozenMetadata++;
            quantityToFreeze--;
        }
    }

    /// @notice Set the portion of sale price (in basis points) that should be paid for token royalties
    /// @param  newRoyaltyFraction The new royalty fraction, in basis points
    function setRoyaltyAmount(uint256 newRoyaltyFraction) external onlyOperatingOfficer {
        _royaltyFraction = newRoyaltyFraction;
    }

    /// @notice Set the URI for tokens that are randomized and not yet revealed
    /// @param  newUnrevealedTokenURI URI of tokens that are randomized, before randomization is done
    function setUnrevealedTokenURI(string calldata newUnrevealedTokenURI) external onlyOperatingOfficer {
        unrevealedTokenURI = newUnrevealedTokenURI;
    }

    /// @notice Set the URI for tokens that are randomized and not yet revealed, overriding for a specific drop
    /// @param  dropID                        The identifier, or batch number, for the drop
    /// @param  newUnrevealedTokenURIOverride URI of tokens that are randomized, before randomization is done
    function setUnrevealedTokenURIOverride(uint64 dropID, string calldata newUnrevealedTokenURIOverride)
        external
        onlyOperatingOfficer
    {
        Drop storage drop = drops[dropID];
        drop.unrevealedTokenURIOverride = newUnrevealedTokenURIOverride;
    }

    /// @notice Hash a password to be used in a randomized drop
    /// @param  password The secret which will be hashed to prepare a drop
    /// @return The hash of the password
    function hashPassword(string calldata password) external pure returns (bytes32) {
        return keccak256(abi.encode(password));
    }

    /// @notice Gets the tokenURI for a token
    /// @dev    If randomness applies to this drop, then it will rotate with the tokenID to find the applicable URI.
    /// @param  tokenID The identifier for the token
    function tokenURI(uint256 tokenID) public view override(ERC721) returns (string memory) {
        require(ERC721._exists(tokenID), "Light: token does not exist");
        (uint64 dropID, uint64 tokenIDInDrop) = _dissectTokenID(tokenID);
        Drop storage drop = drops[dropID];

        if (drop.accumulatedRandomness == 0) {
            // Not randomized
            return string.concat(drop.tokenURIBase, Strings.toString(tokenIDInDrop));
        }
        if (drop.passwordHash != bytes32(0)) {
            // Randomized but not revealed
            if (bytes(drop.unrevealedTokenURIOverride).length > 0) {
                return drop.unrevealedTokenURIOverride;
            }
            return unrevealedTokenURI;
        }
        // Randomized and revealed
        uint256 offset = drop.accumulatedRandomness % drop.quantityForSale;
        uint256 index = (tokenIDInDrop + offset) % drop.quantityForSale;
        return string.concat(drop.tokenURIBase, Strings.toString(index));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ThreeChiefOfficersWithRoyalties, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    /// @dev    Find the effective phase in the drop, revert if no phases are active.
    /// @param  drop An active drop
    /// @return The current drop phase
    function _getEffectivePhase(Drop storage drop) internal view returns (DropPhase memory) {
        require(drop.phases.length > 0, "Light: no drop phases are set");
        require(drop.phases[0].startTime != 0, "Light: first drop phase has no start time");
        require(drop.phases[0].startTime <= block.timestamp, "Light: first drop phase has not started yet");
        uint256 phaseIndex = 0;
        while (phaseIndex < drop.phases.length - 1) {
            if (drop.phases[phaseIndex + 1].startTime <= block.timestamp) {
                phaseIndex++;
            } else {
                break;
            }
        }
        return drop.phases[phaseIndex];
    }

    /// @dev   Require that the message sender is authorized in a given access list.
    /// @param accessListRoot  The designated Merkle tree root
    /// @param accessListProof A Merkle inclusion proof showing the current message sender is on the access list
    /// @param allowedQuantity The quantity of tokens allowed for this msg.sender in this access list
    function _requireValidMerkleProof(
        bytes32 accessListRoot,
        bytes32[] calldata accessListProof,
        uint96 allowedQuantity
    ) internal view {
        bytes32 merkleLeaf = Packing.addressUint96(msg.sender, allowedQuantity);
        require(MerkleProof.verify(accessListProof, accessListRoot, merkleLeaf), "Light: invalid access list proof");
    }

    /// @dev    Generate one token ID inside a drop.
    /// @param  dropID        A identifier, or batch number, for a drop
    /// @param  tokenIDInDrop An identified token inside the drop, from 0 to MAX_DROP_SIZE, inclusive
    /// @return tokenID       The token ID representing the token inside the drop
    function _assembleTokenID(uint64 dropID, uint32 tokenIDInDrop) internal pure returns (uint256 tokenID) {
        return MAX_DROP_SIZE * dropID + tokenIDInDrop;
    }

    /// @dev    Analyze parts in a token ID.
    /// @param  tokenID       A token ID representing a token inside a drop
    /// @return dropID        The identifier, or batch number, for the drop
    /// @return tokenIDInDrop The identified token inside the drop, from 0 to MAX_DROP_SIZE, inclusive
    function _dissectTokenID(uint256 tokenID) internal pure returns (uint64 dropID, uint32 tokenIDInDrop) {
        dropID = uint64(tokenID / MAX_DROP_SIZE);
        tokenIDInDrop = uint32(tokenID % MAX_DROP_SIZE);
    }

    /// @dev   Add one bit of entropy to the entropy pool.
    /// @dev   Entropy pools discussed at https://blog.phor.net/2022/02/04/Randomization-strategies-for-NFT-drops.html
    /// @param dropID            The identifier, or batch number, for the drop
    /// @param additionalEntropy The additional entropy to add one bit from, may be a biased random variable
    function _addEntropyBit(uint64 dropID, uint256 additionalEntropy) internal {
        Drop storage drop = drops[dropID];
        uint256 unbiasedAdditionalEntropy = uint256(keccak256(abi.encode(additionalEntropy)));
        uint256 mixedEntropy = drop.accumulatedRandomness ^ (unbiasedAdditionalEntropy % 2);
        drop.accumulatedRandomness = uint256(keccak256(abi.encode(mixedEntropy)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Packing {
    /// @dev    This packs inputs into a bytes32
    /// @param  a      The first type to pack
    /// @param  b      The second type to pack
    /// @return retval The packed bytes32
    function addressUint96(address a, uint96 b) internal pure returns (bytes32 retval) {
        retval |= bytes32(bytes20(a)); // bits 0...159
        retval |= bytes32(bytes12(b)) >> 160; // bits 160...255
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/interfaces/IERC2981.sol";
import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/utils/introspection/ERC165.sol";

/// @title  Three-party access control inspired by CryptoKitties. By default, the highest-privileged account will be the
///         same account that deploys this contract. ERC-2981 designates royalties to the CFO account. Uses an ownable
///         function to show who is the CEO.
/// @dev    Keep the CEO wallet stored offline, I warned you.
///         Subclassing notes:
///          - Use inheritance to gain functionality from `ThreeChiefOfficers`.
///          - Modify your functions with `onlyOperatingOfficer` to restrict access as needed.
/// @author William Entriken (https://phor.net) from Solidity-Template
abstract contract ThreeChiefOfficersWithRoyalties is IERC2981, ERC165 {
    /// @notice The account that can only reassign officer accounts
    address private _executiveOfficer;

    /// @notice The account that can perform privileged actions
    address private _operatingOfficer;

    /// @notice The account that can collect Ether from this contract
    address payable private _financialOfficer;

    /// @notice The account of recommended royalties for this contract
    uint256 internal _royaltyFraction;

    uint256 internal _royaltyDenominator = 10000;

    /// @dev Revert with an error when attempting privileged access without being executive officer.
    error NotExecutiveOfficer();

    /// @dev Revert with an error when attempting privileged access without being operating officer.
    error NotOperatingOfficer();

    /// @dev Revert with an error when attempting privileged access without being financial officer.
    error NotFinancialOfficer();

    /// @dev The withdrawal operation failed on the receiving side.
    error WithdrawFailed();

    /// @dev This throws unless called by the owner.
    modifier onlyOperatingOfficer() {
        if (msg.sender != _operatingOfficer) {
            revert NotOperatingOfficer();
        }
        _;
    }

    constructor(address payable newFinancialOfficer, uint256 newRoyaltyFraction) {
        _executiveOfficer = msg.sender;
        _financialOfficer = newFinancialOfficer;
        _royaltyFraction = newRoyaltyFraction;
    }

    /// @notice Reassign the executive officer role
    /// @param  newExecutiveOfficer new officer address
    function setExecutiveOfficer(address newExecutiveOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _executiveOfficer = newExecutiveOfficer;
    }

    /// @notice Reassign the operating officer role
    /// @param  newOperatingOfficer new officer address
    function setOperatingOfficer(address payable newOperatingOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _operatingOfficer = newOperatingOfficer;
    }

    /// @notice Reassign the financial officer role
    /// @param  newFinancialOfficer new officer address
    function setFinancialOfficer(address payable newFinancialOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _financialOfficer = newFinancialOfficer;
    }

    /// @notice Collect Ether from this contract
    function withdrawBalance() external {
        if (msg.sender != _financialOfficer) {
            revert NotFinancialOfficer();
        }
        (bool success, ) = _financialOfficer.call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// @notice Get the chief executive officer
    /// @return The chief executive officer account
    function executiveOfficer() public view returns (address) {
        return _executiveOfficer;
    }

    /// @notice Get the chief operating officer
    /// @return The chief operating officer account
    function operatingOfficer() public view returns (address) {
        return _operatingOfficer;
    }

    /// @notice Get the chief financial officer
    /// @return The chief financial officer account
    function financialOfficer() public view returns (address) {
        return _financialOfficer;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * _royaltyFraction) / _royaltyDenominator;
        return (_financialOfficer, royaltyAmount);
    }

    /// @notice EIP-5313 (DRAFT) implementation
    /// @return The account that can control this contract
    function owner() public view returns (address) {
        return _executiveOfficer;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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