// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {IAlphaToken} from "$/interfaces/IAlphaToken.sol";
import {IAlphaDogs} from "$/interfaces/IAlphaDogs.sol";
import {IAlphaDogsAttributes} from "$/interfaces/IAlphaDogsAttributes.sol";

import {Genetics} from "$/libraries/Genetics.sol";
import {Gene} from "$/libraries/Gene.sol";
import {ERC721} from "$/ERC721.sol";

/// @title  AlphaDogs
/// @author Aleph Retamal <github.com/alephao>, Gustavo Tiago <github.com/gutiago>
contract AlphaDogs is IAlphaDogs, ERC721, Ownable, ReentrancyGuard {
    using Gene for uint256;
    using Strings for uint160;
    // ========================================
    // Immutable
    // ========================================

    address private constant BLACKHOLE = address(0);

    /// @notice amount of $ALPHA a staked genesis dog earn per day
    uint256 public constant GENESIS_TOKEN_PER_DAY = 10 ether;

    /// @notice amount of $ALPHA a staked puppy dog earn per day
    uint256 public constant PUPPY_TOKEN_PER_DAY = 2.5 ether;

    /// @notice price in $ALPHA to breed
    uint256 public constant BREEDING_PRICE = 600 ether;

    /// @notice price in $ALPHA to update name or lore of a dog
    uint256 public constant UPDATE_PRICE = 100 ether;

    /// @notice max amount of genesis tokens
    uint32 public immutable maxGenesis;

    /// @notice max amount of puppy tokens
    uint32 public immutable maxPuppies;

    /// @notice address of the $ALPHA ERC20
    IAlphaToken public immutable alphaToken;

    /// @notice merkle tree root for allow-list
    bytes32 public immutable merkleRoot;

    /// @notice number of reserved genesis tokens for wallets in the allow-list
    uint32 public immutable maxReserved;

    // ========================================
    // Mutable
    // ========================================

    /// @notice if the mint function is open
    bool public isSaleActive = false;

    /// @notice if supply should be reserved for allow-list
    bool public isSupplyReserved = true;

    /// @notice amount of genesis minted so far not via allow-list
    uint32 public genesisNonReservedSupply = 0;

    /// @notice amount of genesis minted so far via allow-list
    uint32 public genesisReservedSupply = 0;

    /// @notice amount of puppied minted so far
    uint32 public puppySupply = 0;

    /// @notice map from dog id to custom Name and Lore
    mapping(uint256 => CustomMetadata) internal metadata;

    /// @notice map from dog id to its staked state
    mapping(uint256 => Stake) public getStake;

    /// @notice check if an address already minted
    mapping(address => bool) public didMint;

    /// @notice address of the AlphaDogsAttributes contract
    IAlphaDogsAttributes public attributes;

    // ========================================
    // Constructor
    // ========================================

    constructor(
        uint32 _maxGenesis,
        uint32 _maxPuppies,
        uint32 _maxReserved,
        IAlphaToken _alphaToken,
        IAlphaDogsAttributes _attributes,
        bytes32 _merkleRoot
    ) ERC721("AlphaDogs", "AD") {
        maxGenesis = _maxGenesis;
        maxPuppies = _maxPuppies;
        maxReserved = _maxReserved;
        alphaToken = _alphaToken;
        attributes = _attributes;
        merkleRoot = _merkleRoot;
    }

    // ========================================
    // Modifiers
    // ========================================

    modifier dogzOwner(uint256 id) {
        if (ownerOf[id] != msg.sender) revert InvalidTokenOwner();
        _;
    }

    modifier whenSaleIsActive() {
        if (!isSaleActive) revert NotActive();
        _;
    }

    // " and \ are not valid
    modifier isValidString(string calldata value) {
        bytes memory str = bytes(value);

        for (uint256 i; i < str.length; i++) {
            bytes1 char = str[i];
            if ((char == 0x22) || (char == 0x5c)) revert InvalidChar();
        }
        _;
    }

    // ========================================
    // Owner only
    // ========================================

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        if (isSaleActive == _isSaleActive) revert NotChanged();
        isSaleActive = _isSaleActive;
    }

    function setIsSupplyReserved(bool _isSupplyReserved) external onlyOwner {
        if (isSupplyReserved == _isSupplyReserved) revert NotChanged();
        isSupplyReserved = _isSupplyReserved;
    }

    // ========================================
    // Change NFT Data
    // ========================================

    function setName(uint256 id, string calldata newName)
        external
        override
        dogzOwner(id)
        isValidString(newName)
    {
        bytes memory n = bytes(newName);

        if (n.length > 25) revert InvalidNameLength();
        if (keccak256(n) == keccak256(bytes(metadata[id].name)))
            revert InvalidSameValue();

        metadata[id].name = newName;
        alphaToken.burn(msg.sender, UPDATE_PRICE);
        emit NameChanged(id, newName);
    }

    function setLore(uint256 id, string calldata newLore)
        external
        override
        dogzOwner(id)
        isValidString(newLore)
    {
        bytes memory n = bytes(newLore);

        if (keccak256(n) == keccak256(bytes(metadata[id].lore)))
            revert InvalidSameValue();

        metadata[id].lore = newLore;
        alphaToken.burn(msg.sender, UPDATE_PRICE);
        emit LoreChanged(id, newLore);
    }

    // ========================================
    // Breeding
    // ========================================

    function breed(uint256 mom, uint256 dad)
        external
        override
        dogzOwner(mom)
        dogzOwner(dad)
    {
        if (genesisLeft() != 0) revert NotActive();

        uint256 mintIndex = puppySupply;
        if (mintIndex == maxPuppies) revert InsufficientTokensAvailable();
        if (Gene.isPuppy(mom) || Gene.isPuppy(dad))
            revert FusionWithPuppyForbidden();
        if (mom == dad) revert FusionWithSameParentsForbidden();

        unchecked {
            puppySupply++;
        }

        uint256 puppyId = _generatePuppyTokenIdWithNoCollision(
            mom,
            dad,
            random(mintIndex)
        );
        alphaToken.burn(msg.sender, BREEDING_PRICE);
        //slither-disable-next-line reentrancy-no-eth
        _mint(msg.sender, puppyId);

        emit Breeded(puppyId, mom, dad);
    }

    function _generatePuppyTokenIdWithNoCollision(
        uint256 mom,
        uint256 dad,
        uint256 seed
    ) internal view returns (uint256 tokenId) {
        tokenId = Genetics.uniformCrossOver(mom, dad, seed);
        uint256 i = 3;
        while (ownerOf[tokenId] != BLACKHOLE) {
            tokenId = Genetics.incrementByte(tokenId, i);
            unchecked {
                i++;
            }
        }
    }

    // ========================================
    // Stake / Unstake
    // ========================================

    function stake(uint256[] calldata tokenIds) external override {
        if (tokenIds.length == 0) revert InvalidInput();
        if (msg.sender == address(0)) revert InvalidSender();

        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            // No need to check ownership since transferFrom already checks that
            // and the caller of this function should be the token Owner
            getStake[tokenId] = Stake(msg.sender, uint96(block.timestamp));
            _transfer(msg.sender, address(this), tokenId);
            emit Staked(tokenId);

            unchecked {
                ++i;
            }
        }
    }

    function unstake(uint256[] calldata tokenIds) external override {
        _claim(tokenIds, true);
    }

    function claim(uint256[] calldata tokenIds) external override {
        _claim(tokenIds, false);
    }

    function _claim(uint256[] calldata tokenIds, bool shouldUnstake) internal {
        if (tokenIds.length == 0) revert InvalidInput();
        if (msg.sender == address(0)) revert InvalidSender();

        // total rewards amount to claim
        uint256 totalRewards;

        // loop variables

        // rewards for current genzee in the loop below
        uint256 rewards;

        // current genzeeid in the loop below
        uint256 tokenId;

        // staking information for the current genzee in the loop below
        Stake memory stakeInfo;

        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            stakeInfo = getStake[tokenId];

            if (stakeInfo.owner != msg.sender) revert InvalidTokenOwner();

            uint256 tokensPerDay = tokenId.isPuppy()
                ? PUPPY_TOKEN_PER_DAY
                : GENESIS_TOKEN_PER_DAY;

            rewards = stakeInfo.stakedAt > 1
                ? ((tokensPerDay * (block.timestamp - stakeInfo.stakedAt)) /
                    1 days)
                : 0;
            totalRewards += rewards;

            if (shouldUnstake) {
                getStake[tokenId] = Stake(BLACKHOLE, 1);
                _transfer(address(this), msg.sender, tokenId);
                emit Unstaked(tokenId, rewards);
            } else {
                //slither-disable-next-line incorrect-equality
                if (rewards == 0) revert InvalidAmountToClaim();
                getStake[tokenId].stakedAt = uint96(block.timestamp);
                emit ClaimedTokens(tokenId, rewards);
            }

            unchecked {
                ++i;
            }
        }

        //slither-disable-next-line incorrect-equality
        if (totalRewards == 0) return;
        alphaToken.mint(msg.sender, totalRewards);
    }

    // ========================================
    // Mint
    // ========================================

    function _generateTokenIdWithNoCollision(uint256 seed)
        internal
        view
        returns (uint256 tokenId)
    {
        tokenId = Genetics.generateGenes(seed);
        uint256 i = 3;
        while (ownerOf[tokenId] != BLACKHOLE) {
            tokenId = Genetics.incrementByte(tokenId, i);
            unchecked {
                i++;
            }
        }
    }

    function premint(bytes32[] calldata proof) external whenSaleIsActive {
        uint256 reservedSupply = genesisReservedSupply;

        if (didMint[msg.sender]) revert TokenLimitReached();
        if (reservedSupply + 2 > maxReserved)
            revert InsufficientReservedTokensAvailable();
        if (reservedSupply + genesisNonReservedSupply + 2 > maxGenesis)
            revert InsufficientTokensAvailable();

        bytes32 leaf = keccak256(
            abi.encodePacked(uint160(msg.sender).toHexString(20))
        );
        bool isProofValid = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isProofValid) revert InvalidMerkleProof();

        didMint[msg.sender] = true;

        unchecked {
            uint256 mintIndex = genesisSupply();
            genesisReservedSupply += 2;
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 1))
            );
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 2))
            );
        }
    }

    function mint() external whenSaleIsActive {
        // Can only mint once per address
        if (didMint[msg.sender]) {
            revert TokenLimitReached();
        }

        uint256 reservedSupply = genesisReservedSupply;
        uint256 nonReservedSupply = genesisNonReservedSupply;

        if (reservedSupply + nonReservedSupply + 2 > maxGenesis)
            revert InsufficientTokensAvailable();

        // When minting, if isSupplyReserved is on, public minters won't be able
        // to mint the amount reserved for allow-listed wallets
        if (
            isSupplyReserved && nonReservedSupply + 2 > maxGenesis - maxReserved
        ) {
            revert InsufficientNonReservedTokensAvailable();
        }

        didMint[msg.sender] = true;

        unchecked {
            uint256 mintIndex = genesisSupply();
            genesisNonReservedSupply += 2;
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 1))
            );
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 2))
            );
        }
    }

    function random(uint256 nonce) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin, // solhint-disable-line avoid-tx-origin
                        tx.gasprice,
                        nonce,
                        block.number,
                        block.timestamp
                    )
                )
            );
    }

    // ========================================
    // View
    // ========================================

    function genesisSupply() public view returns (uint32) {
        unchecked {
            return genesisReservedSupply + genesisNonReservedSupply;
        }
    }

    /// @notice amount of tokens left to be minted
    function genesisLeft() public view returns (uint32) {
        unchecked {
            return maxGenesis - genesisSupply();
        }
    }

    /// @notice amount do puppies left to be created
    function puppyTokensLeft() external view returns (uint32) {
        unchecked {
            return maxPuppies - puppySupply;
        }
    }

    /// @notice total supply of nfts
    function totalSupply() external view returns (uint32) {
        unchecked {
            return genesisSupply() + puppySupply;
        }
    }

    function getMetadata(uint256 id)
        external
        view
        override
        returns (CustomMetadata memory)
    {
        return metadata[id];
    }

    // ========================================
    // Overrides
    // ========================================

    function tokenURI(uint256 id)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (ownerOf[id] == BLACKHOLE) revert InvalidTokenID();
        CustomMetadata memory md = metadata[id];
        return attributes.tokenURI(id, bytes(md.name), md.lore);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaToken {
    /// @dev 0x36a1c33f
    error NotChanged();
    /// @dev 0x3d693ada
    error NotAllowed();

    function mint(address addr, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {IAlphaDogsEvents} from "./IAlphaDogsEvents.sol";
import {IAlphaDogsErrors} from "./IAlphaDogsErrors.sol";

interface IAlphaDogs is IAlphaDogsEvents, IAlphaDogsErrors {
    struct CustomMetadata {
        string name;
        string lore;
    }

    struct Stake {
        address owner;
        uint96 stakedAt;
    }

    // mapping(uint256 => CustomMetadata) getMetadata;
    function getMetadata(uint256 id)
        external
        view
        returns (CustomMetadata memory);

    function setName(uint256 id, string calldata newName) external;

    function setLore(uint256 id, string calldata newLore) external;

    function stake(uint256[] calldata tokenIds) external;

    function unstake(uint256[] calldata tokenIds) external;

    function claim(uint256[] calldata tokenIds) external;

    function premint(bytes32[] calldata proof) external;

    function mint() external;

    function breed(uint256 mom, uint256 dad) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsAttributes {
    function tokenURI(
        uint256 id,
        bytes memory name,
        string memory lore
    ) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {Chromossomes} from "./Chromossomes.sol";

/// @title  AlphaDogs Genetics Library
/// @author Aleph Retamal <github.com/alephao>, Gustavo Tiago <github.com/gutiago>
/// @notice Library containing functions for creating and manipulating genes.
///
/// ### Creating a new gene
///
/// • When creating a new gene, we get a pseudo-random seed derive other seeds for each trait
/// • We're using A.J. Walker Alias Algorithm to pick traits with pre-defined rarity table
///   these are the weird hard-coded arrays in the `seedTo{Trait}` functions
/// • Note: we use a pseudo-random seed, meaning that the result can be somewhat manipulated
///   by mad-scientists of the chain.
///
/// ### Breeding
///
/// • For breeding we use uniform cross-over algorithm which is commonly used
///   in genetic algorithms. We walk throught each chromossome, picking from either mom or dad.
library Genetics {
    /// @dev    Generate genes from a seed
    ///
    ///         • Start with                  0x0
    ///         • Add background chromossome  0x77 = 0x0 + 0x77
    ///         • Shift 1 byte to the left    0x7700 = 0x77 << 8
    ///         • Add fur chromossome         0x7766 = 0x7700 + 0x66
    ///         • Same for each chromossome
    function generateGenes(uint256 seed) internal pure returns (uint256 genes) {
        genes |= Chromossomes.seedToBackground(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToFur(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToNeck(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToEyes(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToHat(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToMouth(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToNosering(seed);
    }

    /// @dev Increments the gene i in n (big endian/from right to left)
    ///
    /// ### Examples
    ///
    /// • incrementByte(0x110000, 0) = 0x110001
    /// • incrementByte(0x110000, 1) = 0x110100
    /// • incrementByte(0x110000, 2) = 0x120000
    ///
    /// ### A more readable version of the code
    ///
    /// unchecked {
    ///   uint256 shift = (i % 7) * 8;
    ///   uint256 mask = 0xFF << shift;
    ///   uint256 trait = gene & mask;
    ///   uint256 traitRaw = trait >> shift;
    ///   uint256 newTrait = (traitRaw + 1) % [4, 28, 11, 70, 36, 10, 21][i];
    ///   uint256 tokenIdWithoutOldTrait = ~mask & gene;
    ///   uint256 newGene = tokenIdWithoutOldTrait | (newTrait << shift);
    /// }
    ///
    /// ### Step by step explanation
    ///
    /// Explaining this for devs that look into other contracts to learn stuff like myself
    ///
    /// ### Glossary
    /// • Every 2 positions in an hexadecimal representation of a number = 1 byte
    ///   E.g.: In 0x112233, 11 is a byte, 22 is another byte, 33 is another byte
    /// • Zeros on the left can be ignored so 0x00011 = 0x11, using them here to make
    ///   it easier to see the math
    /// • 1 byte = 8 bits, so 0x1 << 8 will move 1 byte to the left (2 positions) resulting in 0x100
    ///
    /// In this example we have 0x1111221111 and want to increment `22` to `23`
    ///
    /// 1. Create a mask to get only the 22
    ///
    /// 0x1111221111 (gene)
    /// AND
    /// 0x0000FF0000 (mask)
    /// =
    /// 0x0000220000 (result)
    ///
    /// 2. Shift the byte "22" to the least significant byte, so we can increment
    ///
    /// 0x220000 >> (8 * 2) = 0x22
    ///
    /// 3. Increment
    ///
    /// 0x22 + 1 = 0x23. We're also checking against the amount of variants a trait has, that's why
    /// we're doing (byte + 1) % [X, X, X][i]
    ///
    /// 4. Move the byte back to its original position
    ///
    /// 0x23 << (8 * 2) = 0x230000
    ///
    /// 5. Invert the original mask to get all original bytes except the position we're manipulating
    ///
    /// ~0x0000FF0000 = 0xFFFF00FFFF
    ///
    /// 0xFFFF00FFFF
    /// AND
    /// 0x1111221111
    /// =
    /// 0x1111001111
    ///
    /// 6. Put the incremented byte back in the original value
    ///
    /// 0x1111001111
    /// OR
    /// 0x0000230000
    /// =
    /// 0x1111231111
    function incrementByte(uint256 gene, uint256 i)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // Number of bytes to shift, should be between 0 and 7
            uint256 shift = (i % 7) * 8;

            // Create the mask to do all the stuff mentioned in natspec
            uint256 mask = 0xFF << shift;
            return
                (~mask & gene) |
                (((((gene & mask) >> shift) + 1) %
                    [4, 28, 11, 70, 36, 10, 21][i % 7]) << shift);
        }
    }

    /// @dev    Uniform cross-over two "uint7", returns a "uint8" because a child has an extra byte
    /// @param  mom genes from mom
    /// @param  dad genes from dad
    /// @param  seed the seed is used to pick chromossomes between dad and mom.
    ///
    /// @dev If a specific byte in the seed is even, picks mom, otherwise picks dad.
    ///
    /// ### Examples
    ///
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x0) = 0x0111111111111111
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x1) = 0x0111111111111122
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x0101) = 0x0111111111112222
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x010101) = 0x0111111111222222
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x01000100010001) = 0x0122112211221122
    function uniformCrossOver(
        uint256 mom,
        uint256 dad,
        uint256 seed
    ) internal pure returns (uint256) {
        unchecked {
            uint256 child = 0x0100000000000000;
            for (uint256 i = 0; i < 7; i++) {
                // Choose mom or dad to pick the chromossome from
                // If the byte on seed is even, pick mom
                uint256 chromossome = ((seed >> (8 * i)) & 0xFF) % 2 == 0
                    ? mom
                    : dad;

                // Create a mask to pick only the current byte/chromossome
                // E.g.: 3rd byte = 0xFF0000
                uint256 mask = 0xFF << (8 * i);

                // Add byte/chromossome to the child
                child |= (chromossome & mask);
            }

            return child;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

/// @title  AlphaDogs Gene Library
/// @author Aleph Retamal <github.com/alephao>
/// @notice Library containing functions for querying info about a gene.
library Gene {
    /// @notice A gene is puppy if its 8th byte is greater than 0
    function isPuppy(uint256 gene) internal pure returns (bool) {
        return (gene & 0xFF00000000000000) > 0;
    }

    /// @notice Get a specific chromossome in a gene, first position is 0
    function getChromossome(uint256 gene, uint32 position)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint32 shift = 8 * position;
            return (gene & (0xFF << shift)) >> shift;
        }
    }

    function getBackground(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 6);
    }

    function getFur(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 5);
    }

    function getNeck(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 4);
    }

    function getEyes(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 3);
    }

    function getHat(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 2);
    }

    function getMouth(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 1);
    }

    function getNosering(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

// solhint-disable

/// @notice A modified version of Solmate's ERC721 (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @author Solmate, Aleph Retamal <github.com/alephao>
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _transfer(
        address from,
        address to,
        uint256 id
    ) internal {
        require(from == ownerOf[id], "WRONG_FROM");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsEvents {
    event NameChanged(uint256 indexed id, string name);
    event LoreChanged(uint256 indexed id, string lore);
    event Breeded(uint256 indexed child, uint256 mom, uint256 dad);
    event Staked(uint256 indexed id);
    event Unstaked(uint256 indexed id, uint256 amount);
    event ClaimedTokens(uint256 indexed id, uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsErrors {
    /// @dev 0x2783839d
    error InsufficientTokensAvailable();
    /// @dev 0x154e0758
    error InsufficientReservedTokensAvailable();
    /// @dev 0x8152a42e
    error InsufficientNonReservedTokensAvailable();
    /// @dev 0x53bb24f9
    error TokenLimitReached();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0x2c5211c6
    error InvalidAmount();
    /// @dev 0x50e55ae1
    error InvalidAmountToClaim();
    /// @dev 0x6aa2a937
    error InvalidTokenID();
    /// @dev 0x1ae3550b
    error InvalidNameLength();
    /// @dev 0x8a0fcaee
    error InvalidSameValue();
    /// @dev 0x2a7c6b6e
    error InvalidTokenOwner();
    /// @dev 0x8e8ede30
    error FusionWithSameParentsForbidden();
    /// @dev 0x6d074376
    error FusionWithPuppyForbidden();
    /// @dev 0x36a1c33f
    error NotChanged();
    /// @dev 0x80cb55e2
    error NotActive();
    /// @dev 0xb4fa3fb3
    error InvalidInput();
    /// @dev 0xddb5de5e
    error InvalidSender();
    /// @dev 0x21029e82
    error InvalidChar();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

// Generated code. Do not modify!

/// @title  AlphaDogs Chromossome Generator Library
/// @author Aleph Retamal <github.com/alephao>
/// @notice Library containing functions to pick AlphaDogs chromossomes from an uint256 seed.
library Chromossomes {
    // Each of those seedTo{Trait} function select 4 bytes from the seed
    // and use those selected bytes to pick a trait using the A.J. Walker
    // algorithm. The rarity and aliases are calculated beforehand.

    function seedToBackground(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 16) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    154,
                    222,
                    166,
                    200,
                    150,
                    333,
                    97,
                    158,
                    33,
                    162,
                    44,
                    170,
                    93,
                    234,
                    123,
                    94,
                    345,
                    134,
                    66,
                    255,
                    99
                ][trait]
            ) return trait;
            return
                [
                    1,
                    20,
                    1,
                    2,
                    1,
                    3,
                    3,
                    3,
                    5,
                    5,
                    13,
                    9,
                    16,
                    11,
                    16,
                    16,
                    13,
                    16,
                    19,
                    16,
                    19
                ][trait];
        }
    }

    function seedToFur(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 12;
            if (
                traitSeed >> 8 <
                [44, 345, 299, 450, 460, 88, 166, 177, 369, 470, 188, 277][
                    trait
                ]
            ) return trait;
            return [3, 11, 1, 2, 3, 4, 9, 9, 4, 8, 9, 9][trait];
        }
    }

    function seedToNeck(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 34;
            if (
                traitSeed >> 8 <
                [
                    140,
                    333,
                    147,
                    134,
                    878,
                    92,
                    53,
                    100,
                    25,
                    115,
                    90,
                    122,
                    40,
                    6,
                    9,
                    130,
                    3,
                    5,
                    222,
                    4,
                    45,
                    52,
                    57,
                    23,
                    98,
                    50,
                    48,
                    95,
                    27,
                    21,
                    55,
                    47,
                    32,
                    35
                ][trait]
            ) return trait;
            return
                [
                    33,
                    0,
                    1,
                    2,
                    3,
                    0,
                    1,
                    4,
                    1,
                    7,
                    1,
                    9,
                    1,
                    2,
                    4,
                    11,
                    4,
                    4,
                    15,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    9,
                    15,
                    18,
                    18
                ][trait];
        }
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 43;
            if (
                traitSeed >> 8 <
                [
                    30,
                    21,
                    89,
                    7,
                    500,
                    135,
                    52,
                    59,
                    125,
                    88,
                    22,
                    81,
                    120,
                    228,
                    15,
                    90,
                    32,
                    39,
                    17,
                    83,
                    42,
                    12,
                    82,
                    100,
                    84,
                    20,
                    58,
                    56,
                    28,
                    180,
                    40,
                    35,
                    54,
                    55,
                    86,
                    85,
                    24,
                    53,
                    240,
                    80,
                    44,
                    26,
                    16
                ][trait]
            ) return trait;
            return
                [
                    4,
                    4,
                    42,
                    4,
                    2,
                    4,
                    4,
                    4,
                    5,
                    8,
                    4,
                    9,
                    11,
                    12,
                    4,
                    13,
                    4,
                    4,
                    5,
                    15,
                    8,
                    12,
                    19,
                    22,
                    23,
                    13,
                    13,
                    13,
                    13,
                    24,
                    22,
                    29,
                    29,
                    29,
                    29,
                    34,
                    35,
                    38,
                    35,
                    38,
                    38,
                    38,
                    39
                ][trait];
        }
    }

    function seedToHat(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 80) & 0xFFFF;
            uint256 trait = traitSeed % 68;
            if (
                traitSeed >> 8 <
                [
                    18,
                    4,
                    30,
                    35,
                    28,
                    45,
                    46,
                    25,
                    48,
                    22,
                    20,
                    1260,
                    38,
                    43,
                    24,
                    59,
                    38,
                    29,
                    56,
                    30,
                    7,
                    18,
                    25,
                    23,
                    58,
                    42,
                    22,
                    9,
                    6,
                    15,
                    35,
                    22,
                    12,
                    66,
                    27,
                    27,
                    44,
                    46,
                    37,
                    11,
                    28,
                    38,
                    15,
                    42,
                    40,
                    60,
                    37,
                    28,
                    53,
                    50,
                    15,
                    12,
                    5,
                    40,
                    30,
                    8,
                    18,
                    49,
                    48,
                    29,
                    30,
                    10,
                    44,
                    3,
                    35,
                    35,
                    46,
                    35
                ][trait]
            ) return trait;
            return
                [
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    67,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    15,
                    11,
                    11,
                    11,
                    11,
                    11,
                    18,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    24,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    33,
                    11,
                    11,
                    45,
                    48,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    18,
                    33,
                    33,
                    45,
                    49
                ][trait];
        }
    }

    function seedToMouth(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 18;
            if (
                traitSeed >> 8 <
                [
                    156,
                    96,
                    1480,
                    48,
                    333,
                    96,
                    84,
                    32,
                    156,
                    72,
                    24,
                    60,
                    72,
                    84,
                    120,
                    120,
                    168,
                    132
                ][trait]
            ) return trait;
            return
                [2, 2, 17, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4][trait];
        }
    }

    function seedToNosering(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 112) & 0xFFFF;
            uint256 trait = traitSeed % 4;
            if (traitSeed >> 8 < [3201, 12, 84, 36][trait]) return trait;
            return [3, 0, 0, 0][trait];
        }
    }
}