// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    EnumerableSetUpgradeable
} from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";

import {
    MerkleProof
} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import "../extensions/ERC721PartnerSeaDropRandomOffsetUpgradeable.sol";

import "../interfaces/IGorjsToken.sol";

/**
 * @title GORJSGnesisCollection
 * @author Harry.
 * @dev Implementation of Genesis nft collection based on OS Seadrop
 */
contract GORJSGnesisCollection is ERC721PartnerSeaDropRandomOffsetUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    enum MintStage {
        Pause,
        Fkwme
    }

    /// @notice Track the allow list merkle roots.
    bytes32 private _allowListMerkleRoot;

    /// @notice Current mint stage.
    MintStage public mintStage;

    /// @notice ERC20 based yielding token.
    IGorjsToken private _daoToken;

    /** mapping owner => UintSet to store all users stake info*/
    mapping(address => EnumerableSetUpgradeable.UintSet) private userStakeInfo;

    mapping(address => uint256) private mintStatus;
    /**
     * @notice Initialize the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address administrator,
        address daoToken_,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        ERC721PartnerSeaDropUpgradeable.__ERC721PartnerSeaDrop_init(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        );
        _daoToken = IGorjsToken(daoToken_);
    }

    /**
     * @dev Mint stage can only be set by an Admin.
     * @param _mintStage New mint stage to be set.
     * @param merkleRoot_ New hash of root node of merkle tree.
     */
    function setMintStage(MintStage _mintStage, bytes32 merkleRoot_) external onlyOwner {
        mintStage = _mintStage;
        _allowListMerkleRoot = merkleRoot_;
    }

    /**
     * @notice Mint from an allow list.
     *
     * @param quantity         The number of tokens to mint.
     * @param proof            The proof for the leaf of the allow list.
     */
    function mint(uint256 quantity, bytes32[] calldata proof) external {
        // Only users can mint nft.
        require(tx.origin == msg.sender);

        // For stage 4,5(OS Allowlist , Public Mint)
        require(
            mintStage != MintStage.Pause
        );

        require(mintStatus[msg.sender] == 0);
        
        // Verify the proof.
        require(
            MerkleProof.verify(
                proof,
                _allowListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            )
        );

        mintStatus[msg.sender] = 1;
        
        // Mint the token(s), split the payout, emit an event.
        require(_totalMinted() + quantity <= maxSupply());

        // Mint the quantity of tokens to the minter.
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev
     * @param from Account to transfer token from
     * @param to Account to transfer token to
     * @param tokenId Token ID to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        require(address(_daoToken) != address(0));
        require(
            !EnumerableSetUpgradeable.contains(
                userStakeInfo[msg.sender],
                tokenId
            )
        );

        _daoToken.updateRewardsOnTransfer(from, to);

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Claim rewards by holding tokens.
     */
    function claimRewards() external {
        require(address(_daoToken) != address(0));

        _daoToken.claimRewards(msg.sender);
    }

    /** Lock functions */

    /**
     * @dev lock nfts
     * @param _ids NFT Ids to lock
     */
    function lock(uint256[] memory _ids) external {
        require(_ids.length > 0);

        /** lock nfts */
        for (uint256 i; i < _ids.length; ) {
            require(
                !EnumerableSetUpgradeable.contains(
                    userStakeInfo[msg.sender],
                    _ids[i]
                )
            );
            require(ownerOf(_ids[i]) == msg.sender);

            EnumerableSetUpgradeable.add(userStakeInfo[msg.sender], _ids[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev unlock NFTs from the contract
     * @param _ids NFT ids to unlock
     */
    function unlock(uint256[] memory _ids) external {
        require(_ids.length > 0);

        /** transfer nfts from staking cotract to the owner*/
        for (uint256 i; i < _ids.length; ) {
            require(
                EnumerableSetUpgradeable.contains(
                    userStakeInfo[msg.sender],
                    _ids[i]
                )
            );

            EnumerableSetUpgradeable.remove(userStakeInfo[msg.sender], _ids[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return the balance of staked nfts
     * @param _owner the owner address
     */
    function stakeBalanceOf(address _owner) external view returns (uint256) {
        return userStakeInfo[_owner].length();
    }

    /**
     * @dev return the token ids of staked nfts
     * @param _owner the owner address
     */
    function stakedTokens(
        address _owner
    ) external view returns (uint256[] memory) {
        return EnumerableSetUpgradeable.values(userStakeInfo[_owner]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721PartnerSeaDropUpgradeable
} from "../ERC721PartnerSeaDropUpgradeable.sol";
import {
    ERC721PartnerSeaDropRandomOffsetStorage
} from "./ERC721PartnerSeaDropRandomOffsetStorage.sol";
import {
    ERC721ContractMetadataStorage
} from "../ERC721ContractMetadataStorage.sol";

/**
 * @title  ERC721PartnerSeaDropRandomOffset
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721PartnerSeaDropRandomOffset is a token contract that extends
 *         ERC721PartnerSeaDrop to apply a randomOffset to the tokenURI,
 *         to enable fair metadata reveals.
 */
contract ERC721PartnerSeaDropRandomOffsetUpgradeable is
    ERC721PartnerSeaDropUpgradeable
{
    using ERC721PartnerSeaDropRandomOffsetStorage for ERC721PartnerSeaDropRandomOffsetStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;

    /// @notice Revert when setting the randomOffset if already set.
    error AlreadyRevealed();

    /// @notice Revert when setting the randomOffset if the collection is
    ///         not yet fully minted.
    error NotFullyMinted();

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function __ERC721PartnerSeaDropRandomOffset_init(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
        __ReentrancyGuard_init_unchained();
        __ERC721SeaDrop_init_unchained(name, symbol, allowedSeaDrop);
        __TwoStepAdministered_init_unchained(administrator);
        __ERC721PartnerSeaDrop_init_unchained(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        );
        __ERC721PartnerSeaDropRandomOffset_init_unchained(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        );
    }

    function __ERC721PartnerSeaDropRandomOffset_init_unchained(
        string memory,
        string memory,
        address,
        address[] memory
    ) internal onlyInitializing {}

    /**
     * @notice Set the random offset, for a fair metadata reveal. Only callable
     *         by the owner one time when the total number of minted tokens
     *         equals the max supply. Should be called immediately before
     *         reveal.
     */
    function setRandomOffset() external onlyOwner {
        if (ERC721PartnerSeaDropRandomOffsetStorage.layout().revealed) {
            revert AlreadyRevealed();
        }

        if (
            _totalMinted() != ERC721ContractMetadataStorage.layout()._maxSupply
        ) {
            revert NotFullyMinted();
        }
        // block.difficulty returns PREVRANDAO on Ethereum post-merge
        // NOTE: do not use this on other chains
        // randomOffset returns between 1 and MAX_SUPPLY
        ERC721PartnerSeaDropRandomOffsetStorage.layout().randomOffset =
            (uint256(keccak256(abi.encode(block.difficulty))) %
                (ERC721ContractMetadataStorage.layout()._maxSupply - 1)) +
            1;

        ERC721PartnerSeaDropRandomOffsetStorage.layout().revealed = true;
    }

    /**
     * @notice The token URI, offset by randomOffset, to enable fair metadata
     *         reveals.
     *
     * @param tokenId The token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            // If there is no baseURI set, return an empty string.
            return "";
        } else {
            if (!ERC721PartnerSeaDropRandomOffsetStorage.layout().revealed) {
                // If the baseURI is set but the collection is not revealed yet,
                // return just the baseURI.
                return base;
            } else {
                // If the baseURI is set and the collection is revealed,
                // return the tokenURI offset by the randomOffset.
                return
                    string.concat(
                        base,
                        _toString(
                            ((tokenId +
                                ERC721PartnerSeaDropRandomOffsetStorage
                                    .layout()
                                    .randomOffset) %
                                ERC721ContractMetadataStorage
                                    .layout()
                                    ._maxSupply) + _startTokenId()
                        )
                    );
            }
        }
    }

    function randomOffset() public view returns (uint256) {
        return ERC721PartnerSeaDropRandomOffsetStorage.layout().randomOffset;
    }

    function revealed() public view returns (bool) {
        return ERC721PartnerSeaDropRandomOffsetStorage.layout().revealed;
    }
}

//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

interface IGorjsToken is IERC20Upgradeable{
    
    function updateRewardsOnMint(address account, uint256 amountMinted) external;
    
    function updateRewardsOnTransfer(address from, address to) external;

    function claimRewards(address account) external;

    function lockToken(address account, uint256 proposalId, uint256 amount) external;

    function unlockToken(address account) external;

    function getLockedAmount(address account) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

import { ERC721SeaDropUpgradeable } from "./ERC721SeaDropUpgradeable.sol";

import { ISeaDropUpgradeable } from "./interfaces/ISeaDropUpgradeable.sol";

import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "./lib/SeaDropStructsUpgradeable.sol";

import {
    TwoStepAdministeredUpgradeable
} from "../lib-upgradeable/utility-contracts/src/TwoStepAdministeredUpgradeable.sol";
import {
    TwoStepAdministeredStorage
} from "../lib-upgradeable/utility-contracts/src/TwoStepAdministeredStorage.sol";

/**
 * @title  ERC721PartnerSeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721PartnerSeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop, with additional administrative
 *         functionality tailored for business requirements around partnered
 *         mints with off-chain agreements in place between two parties.
 *
 *         The "Owner" should control mint specifics such as price and start.
 *         The "Administrator" should control fee parameters.
 *
 *         Otherwise, for ease of administration, either Owner or Administrator
 *         should be able to configure mint parameters. They have the ability
 *         to override each other's actions in many circumstances, which is
 *         why the establishment of off-chain trust is important.
 *
 *         Note: An Administrator is not required to interface with SeaDrop.
 */
contract ERC721PartnerSeaDropUpgradeable is
    ERC721SeaDropUpgradeable,
    TwoStepAdministeredUpgradeable
{
    using TwoStepAdministeredStorage for TwoStepAdministeredStorage.Layout;

    /// @notice To prevent Owner from overriding fees, Administrator must
    ///         first initialize with fee.
    error AdministratorMustInitializeWithFee();

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function __ERC721PartnerSeaDrop_init(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
        __ReentrancyGuard_init_unchained();
        __ERC721SeaDrop_init_unchained(name, symbol, allowedSeaDrop);
        __TwoStepAdministered_init_unchained(administrator);
        __ERC721PartnerSeaDrop_init_unchained(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        );
    }

    function __ERC721PartnerSeaDrop_init_unchained(
        string memory,
        string memory,
        address,
        address[] memory
    ) internal onlyInitializing {}

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _mint(minter, quantity);
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        override
        onlyOwnerOrAdministrator
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override onlyOwnerOrAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Track the previous public drop data.
        PublicDrop memory retrieved = ISeaDropUpgradeable(seaDropImpl)
            .getPublicDrop(address(this));

        // Track the newly supplied drop data.
        PublicDrop memory supplied = publicDrop;

        // Only the administrator (OpenSea) can set feeBps.
        if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
            // Administrator must first set fee.
            if (retrieved.maxTotalMintableByWallet == 0) {
                revert AdministratorMustInitializeWithFee();
            }
            supplied.feeBps = retrieved.feeBps;
            supplied.restrictFeeRecipients = true;
        } else {
            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
            uint16 maxTotalMintableByWallet = retrieved
                .maxTotalMintableByWallet;
            retrieved.maxTotalMintableByWallet = maxTotalMintableByWallet > 0
                ? maxTotalMintableByWallet
                : 1;
            retrieved.feeBps = supplied.feeBps;
            retrieved.restrictFeeRecipients = true;
            supplied = retrieved;
        }

        // Update the public drop data on SeaDrop.
        ISeaDropUpgradeable(seaDropImpl).updatePublicDrop(supplied);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external virtual override onlyOwnerOrAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allow list on SeaDrop.
        ISeaDropUpgradeable(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator must first set `feeBps`.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external virtual override onlyOwnerOrAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Track the previous drop stage data.
        TokenGatedDropStage memory retrieved = ISeaDropUpgradeable(seaDropImpl)
            .getTokenGatedDrop(address(this), allowedNftToken);

        // Track the newly supplied drop data.
        TokenGatedDropStage memory supplied = dropStage;

        // Only the administrator (OpenSea) can set feeBps on Partner
        // contracts.
        if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
            // Administrator must first set fee.
            if (retrieved.maxTotalMintableByWallet == 0) {
                revert AdministratorMustInitializeWithFee();
            }
            supplied.feeBps = retrieved.feeBps;
            supplied.restrictFeeRecipients = true;
        } else {
            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
            uint16 maxTotalMintableByWallet = retrieved
                .maxTotalMintableByWallet;
            retrieved.maxTotalMintableByWallet = maxTotalMintableByWallet > 0
                ? maxTotalMintableByWallet
                : 1;
            retrieved.feeBps = supplied.feeBps;
            retrieved.restrictFeeRecipients = true;
            supplied = retrieved;
        }

        // Update the token gated drop stage.
        ISeaDropUpgradeable(seaDropImpl).updateTokenGatedDrop(
            allowedNftToken,
            supplied
        );
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
        onlyOwnerOrAdministrator
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the drop URI.
        ISeaDropUpgradeable(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external override onlyAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allowed fee recipient.
        ISeaDropUpgradeable(seaDropImpl).updateAllowedFeeRecipient(
            feeRecipient,
            allowed
        );
    }

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters to
     *                                   enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external virtual override onlyOwnerOrAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Track the previous signed mint validation params.
        SignedMintValidationParams memory retrieved = ISeaDropUpgradeable(
            seaDropImpl
        ).getSignedMintValidationParams(address(this), signer);

        // Track the newly supplied params.
        SignedMintValidationParams memory supplied = signedMintValidationParams;

        // Only the administrator (OpenSea) can set feeBps on Partner
        // contracts.
        if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
            // Administrator must first set fee.
            if (retrieved.maxMaxTotalMintableByWallet == 0) {
                revert AdministratorMustInitializeWithFee();
            }
            supplied.minFeeBps = retrieved.minFeeBps;
            supplied.maxFeeBps = retrieved.maxFeeBps;
        } else {
            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
            uint24 maxMaxTotalMintableByWallet = retrieved
                .maxMaxTotalMintableByWallet;
            retrieved
                .maxMaxTotalMintableByWallet = maxMaxTotalMintableByWallet > 0
                ? maxMaxTotalMintableByWallet
                : 1;
            retrieved.minFeeBps = supplied.minFeeBps;
            retrieved.maxFeeBps = supplied.maxFeeBps;
            supplied = retrieved;
        }

        // Update the signed mint validation params.
        ISeaDropUpgradeable(seaDropImpl).updateSignedMintValidationParams(
            signer,
            supplied
        );
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external virtual override onlyOwnerOrAdministrator {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the payer.
        ISeaDropUpgradeable(seaDropImpl).updatePayer(payer, allowed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {
    ERC721ContractMetadataUpgradeable
} from "./ERC721ContractMetadataUpgradeable.sol";

import {
    ISeaDropTokenContractMetadataUpgradeable
} from "./interfaces/ISeaDropTokenContractMetadataUpgradeable.sol";

library ERC721ContractMetadataStorage {
    struct Layout {
        /// @notice Track the max supply.
        uint256 _maxSupply;
        /// @notice Track the base URI for token metadata.
        string _tokenBaseURI;
        /// @notice Track the contract URI for contract metadata.
        string _contractURI;
        /// @notice Track the provenance hash for guaranteeing metadata order
        ///         for random reveals.
        bytes32 _provenanceHash;
        /// @notice Track the royalty info: address to receive royalties, and
        ///         royalty basis points.
        ISeaDropTokenContractMetadataUpgradeable.RoyaltyInfo _royaltyInfo;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzepplin.contracts.storage.ERC721ContractMetadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721PartnerSeaDropRandomOffsetUpgradeable
} from "./ERC721PartnerSeaDropRandomOffsetUpgradeable.sol";

import {
    ERC721ContractMetadataUpgradeable
} from "../ERC721ContractMetadataUpgradeable.sol";

library ERC721PartnerSeaDropRandomOffsetStorage {
    struct Layout {
        /// @notice The random offset, between 1 and the MAX_SUPPLY at the time of
        ///         being set.
        uint256 randomOffset;
        /// @notice If the collection has been revealed and the randomOffset has
        ///         been set.
        bool revealed;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256(
            "openzepplin.contracts.storage.ERC721PartnerSeaDropRandomOffset"
        );

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721ContractMetadataUpgradeable,
    ISeaDropTokenContractMetadataUpgradeable
} from "./ERC721ContractMetadataUpgradeable.sol";

import {
    INonFungibleSeaDropTokenUpgradeable
} from "./interfaces/INonFungibleSeaDropTokenUpgradeable.sol";

import { ISeaDropUpgradeable } from "./interfaces/ISeaDropUpgradeable.sol";

import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "./lib/SeaDropStructsUpgradeable.sol";

import {
    ERC721SeaDropStructsErrorsAndEventsUpgradeable
} from "./lib/ERC721SeaDropStructsErrorsAndEventsUpgradeable.sol";

import {
    ReentrancyGuardUpgradeable
} from "../lib-upgradeable/solmate/src/utils/ReentrancyGuardUpgradeable.sol";

import {
    IERC165Upgradeable
} from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";

import {
    DefaultOperatorFiltererUpgradeable
} from "../lib-upgradeable/operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import { ERC721SeaDropStorage } from "./ERC721SeaDropStorage.sol";

import {
    ERC721ContractMetadataStorage
} from "./ERC721ContractMetadataStorage.sol";

/**
 * @title  ERC721SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC721SeaDropUpgradeable is
    ERC721ContractMetadataUpgradeable,
    INonFungibleSeaDropTokenUpgradeable,
    ERC721SeaDropStructsErrorsAndEventsUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using ERC721SeaDropStorage for ERC721SeaDropStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;

    /**
     * @dev Reverts if not an allowed SeaDrop contract.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     *
     * @param seaDrop The SeaDrop address to check if allowed.
     */
    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (ERC721SeaDropStorage.layout()._allowedSeaDrop[seaDrop] != true) {
            revert OnlyAllowedSeaDrop();
        }
    }

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    function __ERC721SeaDrop_init(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
        __ReentrancyGuard_init_unchained();
        __DefaultOperatorFilterer_init();
        __ERC721SeaDrop_init_unchained(name, symbol, allowedSeaDrop);
    }

    function __ERC721SeaDrop_init_unchained(
        string memory,
        string memory,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        // Put the length on the stack for more efficient access.
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            ERC721SeaDropStorage.layout()._allowedSeaDrop[
                allowedSeaDrop[i]
            ] = true;

            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        ERC721SeaDropStorage
            .layout()
            ._enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event noting the contract deployment.
        emit SeaDropTokenDeployed();
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = ERC721SeaDropStorage
            .layout()
            ._enumeratedAllowedSeaDrop
            .length;

        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            ERC721SeaDropStorage.layout()._allowedSeaDrop[
                ERC721SeaDropStorage.layout()._enumeratedAllowedSeaDrop[i]
            ] = false;

            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            ERC721SeaDropStorage.layout()._allowedSeaDrop[
                allowedSeaDrop[i]
            ] = true;

            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        ERC721SeaDropStorage
            .layout()
            ._enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     *
     *      This is to avoid future possible problems since `0` is usually
     *      used to signal values that have not been set or have been removed.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
        nonReentrant
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _safeMint(minter, quantity);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDropUpgradeable(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external virtual override onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allow list on SeaDrop.
        ISeaDropUpgradeable(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner can use this function.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external virtual override onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the token gated drop stage.
        ISeaDropUpgradeable(seaDropImpl).updateTokenGatedDrop(
            allowedNftToken,
            dropStage
        );
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
        onlyOwner
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the drop URI.
        ISeaDropUpgradeable(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the creator payout address.
        ISeaDropUpgradeable(seaDropImpl).updateCreatorPayoutAddress(
            payoutAddress
        );
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the owner can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external virtual onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allowed fee recipient.
        ISeaDropUpgradeable(seaDropImpl).updateAllowedFeeRecipient(
            feeRecipient,
            allowed
        );
    }

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters to
     *                                   enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external virtual override onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the signer.
        ISeaDropUpgradeable(seaDropImpl).updateSignedMintValidationParams(
            signer,
            signedMintValidationParams
        );
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external virtual override onlyOwner {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the payer.
        ISeaDropUpgradeable(seaDropImpl).updatePayer(payer, allowed);
    }

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        override
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        )
    {
        minterNumMinted = _numberMinted(minter);
        currentTotalSupply = _totalMinted();
        maxSupply = ERC721ContractMetadataStorage.layout()._maxSupply;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721ContractMetadataUpgradeable)
        returns (bool)
    {
        return
            interfaceId ==
            type(INonFungibleSeaDropTokenUpgradeable).interfaceId ||
            interfaceId ==
            type(ISeaDropTokenContractMetadataUpgradeable).interfaceId ||
            // ERC721ContractMetadata returns supportsInterface true for
            //     EIP-2981
            // ERC721A returns supportsInterface true for
            //     ERC165, ERC721, ERC721Metadata
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - The `operator` must be allowed.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

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
     * - The `operator` mut be allowed.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

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
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
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
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     *         Note: The individual configure methods should be used
     *         to unset or reset any properties to zero, as this method
     *         will ignore zero-value properties in the config struct.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigureStruct calldata config)
        external
        onlyOwner
    {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (bytes(config.baseURI).length != 0) {
            this.setBaseURI(config.baseURI);
        }
        if (bytes(config.contractURI).length != 0) {
            this.setContractURI(config.contractURI);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }
        if (bytes(config.dropURI).length != 0) {
            this.updateDropURI(config.seaDropImpl, config.dropURI);
        }
        if (config.allowListData.merkleRoot != bytes32(0)) {
            this.updateAllowList(config.seaDropImpl, config.allowListData);
        }
        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.provenanceHash != bytes32(0)) {
            this.setProvenanceHash(config.provenanceHash);
        }
        if (config.allowedFeeRecipients.length > 0) {
            for (uint256 i = 0; i < config.allowedFeeRecipients.length; ) {
                this.updateAllowedFeeRecipient(
                    config.seaDropImpl,
                    config.allowedFeeRecipients[i],
                    true
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedFeeRecipients.length > 0) {
            for (uint256 i = 0; i < config.disallowedFeeRecipients.length; ) {
                this.updateAllowedFeeRecipient(
                    config.seaDropImpl,
                    config.disallowedFeeRecipients[i],
                    false
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.allowedPayers.length > 0) {
            for (uint256 i = 0; i < config.allowedPayers.length; ) {
                this.updatePayer(
                    config.seaDropImpl,
                    config.allowedPayers[i],
                    true
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedPayers.length > 0) {
            for (uint256 i = 0; i < config.disallowedPayers.length; ) {
                this.updatePayer(
                    config.seaDropImpl,
                    config.disallowedPayers[i],
                    false
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.tokenGatedDropStages.length > 0) {
            if (
                config.tokenGatedDropStages.length !=
                config.tokenGatedAllowedNftTokens.length
            ) {
                revert TokenGatedMismatch();
            }
            for (uint256 i = 0; i < config.tokenGatedDropStages.length; ) {
                this.updateTokenGatedDrop(
                    config.seaDropImpl,
                    config.tokenGatedAllowedNftTokens[i],
                    config.tokenGatedDropStages[i]
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedTokenGatedAllowedNftTokens.length > 0) {
            for (
                uint256 i = 0;
                i < config.disallowedTokenGatedAllowedNftTokens.length;

            ) {
                TokenGatedDropStage memory emptyStage;
                this.updateTokenGatedDrop(
                    config.seaDropImpl,
                    config.disallowedTokenGatedAllowedNftTokens[i],
                    emptyStage
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.signedMintValidationParams.length > 0) {
            if (
                config.signedMintValidationParams.length !=
                config.signers.length
            ) {
                revert SignersMismatch();
            }
            for (
                uint256 i = 0;
                i < config.signedMintValidationParams.length;

            ) {
                this.updateSignedMintValidationParams(
                    config.seaDropImpl,
                    config.signers[i],
                    config.signedMintValidationParams[i]
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedSigners.length > 0) {
            for (uint256 i = 0; i < config.disallowedSigners.length; ) {
                SignedMintValidationParams memory emptyParams;
                this.updateSignedMintValidationParams(
                    config.seaDropImpl,
                    config.disallowedSigners[i],
                    emptyParams
                );
                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AllowListData,
    MintParams,
    PublicDrop,
    TokenGatedDropStage,
    TokenGatedMintParams,
    SignedMintValidationParams
} from "../lib/SeaDropStructsUpgradeable.sol";

import {
    SeaDropErrorsAndEventsUpgradeable
} from "../lib/SeaDropErrorsAndEventsUpgradeable.sol";

interface ISeaDropUpgradeable is SeaDropErrorsAndEventsUpgradeable {
    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity
    ) external payable;

    /**
     * @notice Mint from an allow list.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     * @param mintParams       The mint parameters.
     * @param proof            The proof for the leaf of the allow list.
     */
    function mintAllowList(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        bytes32[] calldata proof
    ) external payable;

    /**
     * @notice Mint with a server-side signature.
     *         Note that a signature can only be used once.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     * @param mintParams       The mint parameters.
     * @param salt             The sale for the signed mint.
     * @param signature        The server-side signature, must be an allowed
     *                         signer.
     */
    function mintSigned(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        uint256 salt,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Mint as an allowed token holder.
     *         This will mark the token id as redeemed and will revert if the
     *         same token id is attempted to be redeemed twice.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param mintParams       The token gated mint params.
     */
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        TokenGatedMintParams calldata mintParams
    ) external payable;

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory);

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the allow list merkle root for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getAllowListMerkleRoot(address nftContract)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns if the specified fee recipient is allowed
     *         for the nft contract.
     *
     * @param nftContract  The nft contract.
     * @param feeRecipient The fee recipient.
     */
    function getFeeRecipientIsAllowed(address nftContract, address feeRecipient)
        external
        view
        returns (bool);

    /**
     * @notice Returns an enumeration of allowed fee recipients for an
     *         nft contract when fee recipients are enforced
     *
     * @param nftContract The nft contract.
     */
    function getAllowedFeeRecipients(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the server-side signers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigners(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the struct of SignedMintValidationParams for a signer.
     *
     * @param nftContract The nft contract.
     * @param signer      The signer.
     */
    function getSignedMintValidationParams(address nftContract, address signer)
        external
        view
        returns (SignedMintValidationParams memory);

    /**
     * @notice Returns the payers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPayers(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns if the specified payer is allowed
     *         for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param payer       The payer.
     */
    function getPayerIsAllowed(address nftContract, address payer)
        external
        view
        returns (bool);

    /**
     * @notice Returns the allowed token gated drop tokens for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getTokenGatedAllowedTokens(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the token gated drop data for the nft contract
     *         and token gated nft.
     *
     * @param nftContract     The nft contract.
     * @param allowedNftToken The token gated nft token.
     */
    function getTokenGatedDrop(address nftContract, address allowedNftToken)
        external
        view
        returns (TokenGatedDropStage memory);

    /**
     * @notice Returns whether the token id for a token gated drop has been
     *         redeemed.
     *
     * @param nftContract       The nft contract.
     * @param allowedNftToken   The token gated nft token.
     * @param allowedNftTokenId The token gated nft token id to check.
     */
    function getAllowedNftTokenIdIsRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    ) external view returns (bool);

    /**
     * The following methods assume msg.sender is an nft contract
     * and its ERC165 interface id matches INonFungibleSeaDropToken.
     */

    /**
     * @notice Emits an event to notify update of the drop URI.
     *
     * @param dropURI The new drop URI.
     */
    function updateDropURI(string calldata dropURI) external;

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the allow list merkle root for the nft contract
     *         and emits an event.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param allowListData The allow list data.
     */
    function updateAllowList(AllowListData calldata allowListData) external;

    /**
     * @notice Updates the token gated drop stage for the nft contract
     *         and emits an event.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing simultaneous
     *         token gated drop promotions for each other, they can be
     *         minted by the same actor until `maxTokenSupplyForStage`
     *         is reached. Please ensure the `allowedNftToken` is not
     *         running an active drop during the `dropStage` time period.
     *
     * @param allowedNftToken The token gated nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the allowed fee recipient and emits an event.
     *
     * @param feeRecipient The fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed)
        external;

    /**
     * @notice Updates the allowed server-side signers and emits an event.
     *
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters
     *                                   to enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address signer,
        SignedMintValidationParams calldata signedMintValidationParams
    ) external;

    /**
     * @notice Updates the allowed payer and emits an event.
     *
     * @param payer   The payer to add or remove.
     * @param allowed Whether to add or remove the payer.
     */
    function updatePayer(address payer, bool allowed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m
 *                                 of native token, e.g. ETH, MATIC)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTIme                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct PublicDrop {
    uint80 mintPrice; // 80/256 bits
    uint48 startTime; // 128/256 bits
    uint48 endTime; // 176/256 bits
    uint16 maxTotalMintableByWallet; // 224/256 bits
    uint16 feeBps; // 240/256 bits
    bool restrictFeeRecipients; // 248/256 bits
}

/**
 * @notice A struct defining token gated drop stage data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m 
 *                                 of native token, e.g.: ETH, MATIC)
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be 
 *                                 non-zero since the public mint emits
 *                                 with index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct TokenGatedDropStage {
    uint80 mintPrice; // 80/256 bits
    uint16 maxTotalMintableByWallet; // 96/256 bits
    uint48 startTime; // 144/256 bits
    uint48 endTime; // 192/256 bits
    uint8 dropStageIndex; // non-zero. 200/256 bits
    uint32 maxTokenSupplyForStage; // 232/256 bits
    uint16 feeBps; // 248/256 bits
    bool restrictFeeRecipients; // 256/256 bits
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 * 
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 * 
 * @param mintPrice                The mint price per token.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be
 *                                 non-zero since the public mint emits with
 *                                 index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct MintParams {
    uint256 mintPrice; 
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex; // non-zero
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @notice A struct defining token gated mint params.
 * 
 * @param allowedNftToken    The allowed nft token contract address.
 * @param allowedNftTokenIds The token ids to redeem.
 */
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/**
 * @notice A struct defining allow list data (for minting an allow list).
 * 
 * @param merkleRoot    The merkle root for the allow list.
 * @param publicKeyURIs If the allowListURI is encrypted, a list of URIs
 *                      pointing to the public keys. Empty if unencrypted.
 * @param allowListURI  The URI for the allow list.
 */
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/**
 * @notice A struct defining minimum and maximum parameters to validate for 
 *         signed mints, to minimize negative effects of a compromised signer.
 *
 * @param minMintPrice                The minimum mint price allowed.
 * @param maxMaxTotalMintableByWallet The maximum total number of mints allowed
 *                                    by a wallet.
 * @param minStartTime                The minimum start time allowed.
 * @param maxEndTime                  The maximum end time allowed.
 * @param maxMaxTokenSupplyForStage   The maximum token supply allowed.
 * @param minFeeBps                   The minimum fee allowed.
 * @param maxFeeBps                   The maximum fee allowed.
 */
struct SignedMintValidationParams {
    uint80 minMintPrice; // 80/256 bits
    uint24 maxMaxTotalMintableByWallet; // 104/256 bits
    uint40 minStartTime; // 144/256 bits
    uint40 maxEndTime; // 184/256 bits
    uint40 maxMaxTokenSupplyForStage; // 224/256 bits
    uint16 minFeeBps; // 240/256 bits
    uint16 maxFeeBps; // 256/256 bits
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { TwoStepOwnableUpgradeable } from "./TwoStepOwnableUpgradeable.sol";
import { TwoStepAdministeredStorage } from "./TwoStepAdministeredStorage.sol";
import "../../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract TwoStepAdministeredUpgradeable is
    Initializable,
    TwoStepOwnableUpgradeable
{
    using TwoStepAdministeredStorage for TwoStepAdministeredStorage.Layout;
    event AdministratorUpdated(
        address indexed previousAdministrator,
        address indexed newAdministrator
    );
    event PotentialAdministratorUpdated(address newPotentialAdministrator);

    error OnlyAdministrator();
    error OnlyOwnerOrAdministrator();
    error NotNextAdministrator();
    error NewAdministratorIsZeroAddress();

    modifier onlyAdministrator() virtual {
        if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
            revert OnlyAdministrator();
        }

        _;
    }

    modifier onlyOwnerOrAdministrator() virtual {
        if (msg.sender != owner()) {
            if (
                msg.sender != TwoStepAdministeredStorage.layout().administrator
            ) {
                revert OnlyOwnerOrAdministrator();
            }
        }
        _;
    }

    function __TwoStepAdministered_init(
        address _administrator
    ) internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __TwoStepAdministered_init_unchained(_administrator);
    }

    function __TwoStepAdministered_init_unchained(
        address _administrator
    ) internal onlyInitializing {
        _initialize(_administrator);
    }

    function _initialize(address _administrator) private onlyConstructor {
        TwoStepAdministeredStorage.layout().administrator = _administrator;
        emit AdministratorUpdated(address(0), _administrator);
    }

    function transferAdministration(
        address newAdministrator
    ) public virtual onlyAdministrator {
        if (newAdministrator == address(0)) {
            revert NewAdministratorIsZeroAddress();
        }
        TwoStepAdministeredStorage
            .layout()
            .potentialAdministrator = newAdministrator;
        emit PotentialAdministratorUpdated(newAdministrator);
    }

    function _transferAdministration(
        address newAdministrator
    ) internal virtual {
        TwoStepAdministeredStorage.layout().administrator = newAdministrator;

        emit AdministratorUpdated(msg.sender, newAdministrator);
    }

    ///@notice Acept administration of smart contract, after the current administrator has initiated the process with transferAdministration
    function acceptAdministration() public virtual {
        address _potentialAdministrator = TwoStepAdministeredStorage
            .layout()
            .potentialAdministrator;
        if (msg.sender != _potentialAdministrator) {
            revert NotNextAdministrator();
        }
        _transferAdministration(_potentialAdministrator);
        delete TwoStepAdministeredStorage.layout().potentialAdministrator;
    }

    ///@notice cancel administration transfer
    function cancelAdministrationTransfer() public virtual onlyAdministrator {
        delete TwoStepAdministeredStorage.layout().potentialAdministrator;
        emit PotentialAdministratorUpdated(address(0));
    }

    function renounceAdministration() public virtual onlyAdministrator {
        delete TwoStepAdministeredStorage.layout().administrator;
        emit AdministratorUpdated(msg.sender, address(0));
    }

    // generated getter for ${varDecl.name}
    function administrator() public view returns (address) {
        return TwoStepAdministeredStorage.layout().administrator;
    }

    // generated getter for ${varDecl.name}
    function potentialAdministrator() public view returns (address) {
        return TwoStepAdministeredStorage.layout().potentialAdministrator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { TwoStepAdministeredUpgradeable } from "./TwoStepAdministeredUpgradeable.sol";

library TwoStepAdministeredStorage {

  struct Layout {

    address administrator;
    address potentialAdministrator;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.TwoStepAdministered');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ISeaDropTokenContractMetadataUpgradeable
} from "./interfaces/ISeaDropTokenContractMetadataUpgradeable.sol";

import {
    ERC721AUpgradeable
} from "../lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol";

import {
    TwoStepOwnableUpgradeable
} from "../lib-upgradeable/utility-contracts/src/TwoStepOwnableUpgradeable.sol";

import {
    IERC2981Upgradeable
} from "../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

import {
    IERC165Upgradeable
} from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";

import {
    ERC721ContractMetadataStorage
} from "./ERC721ContractMetadataStorage.sol";

/**
 * @title  ERC721ContractMetadata
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721ContractMetadata is a token contract that extends ERC721A
 *         with additional metadata and ownership capabilities.
 */
contract ERC721ContractMetadataUpgradeable is
    ERC721AUpgradeable,
    TwoStepOwnableUpgradeable,
    ISeaDropTokenContractMetadataUpgradeable
{
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    function __ERC721ContractMetadata_init(
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
    }

    function __ERC721ContractMetadata_init_unchained(
        string memory,
        string memory
    ) internal onlyInitializing {}

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string calldata newBaseURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new base URI.
        ERC721ContractMetadataStorage.layout()._tokenBaseURI = newBaseURI;

        // Emit an event with the update.
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new contract URI.
        ERC721ContractMetadataStorage.layout()._contractURI = newContractURI;

        // Emit an event with the update.
        emit ContractURIUpdated(newContractURI);
    }

    /**
     * @notice Emit an event notifying metadata updates for
     *         a range of token ids, according to EIP-4906.
     *
     * @param fromTokenId The start token id.
     * @param toTokenId   The end token id.
     */
    function emitBatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId)
        external
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Emit an event with the update.
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2**64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        ERC721ContractMetadataStorage.layout()._maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint has started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if any items have been minted.
        if (_totalMinted() > 0) {
            revert ProvenanceHashCannotBeSetAfterMintStarted();
        }

        // Keep track of the old provenance hash for emitting with the event.
        bytes32 oldProvenanceHash = ERC721ContractMetadataStorage
            .layout()
            ._provenanceHash;

        // Set the new provenance hash.
        ERC721ContractMetadataStorage
            .layout()
            ._provenanceHash = newProvenanceHash;

        // Emit an event with the update.
        emit ProvenanceHashUpdated(oldProvenanceHash, newProvenanceHash);
    }

    /**
     * @notice Sets the address and basis points for royalties.
     *
     * @param newInfo The struct to configure royalties.
     */
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if the new royalty address is the zero address.
        if (newInfo.royaltyAddress == address(0)) {
            revert RoyaltyAddressCannotBeZeroAddress();
        }

        // Revert if the new basis points is greater than 10_000.
        if (newInfo.royaltyBps > 10_000) {
            revert InvalidRoyaltyBasisPoints(newInfo.royaltyBps);
        }

        // Set the new royalty info.
        ERC721ContractMetadataStorage.layout()._royaltyInfo = newInfo;

        // Emit an event with the updated params.
        emit RoyaltyInfoUpdated(newInfo.royaltyAddress, newInfo.royaltyBps);
    }

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return ERC721ContractMetadataStorage.layout()._tokenBaseURI;
    }

    /**
     * @notice Returns the contract URI for contract metadata.
     */
    function contractURI() external view override returns (string memory) {
        return ERC721ContractMetadataStorage.layout()._contractURI;
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return ERC721ContractMetadataStorage.layout()._maxSupply;
    }

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view override returns (bytes32) {
        return ERC721ContractMetadataStorage.layout()._provenanceHash;
    }

    /**
     * @notice Returns the address that receives royalties.
     */
    function royaltyAddress() external view returns (address) {
        return
            ERC721ContractMetadataStorage.layout()._royaltyInfo.royaltyAddress;
    }

    /**
     * @notice Returns the royalty basis points out of 10_000.
     */
    function royaltyBasisPoints() external view returns (uint256) {
        return ERC721ContractMetadataStorage.layout()._royaltyInfo.royaltyBps;
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @ param  _tokenId     The NFT asset queried for royalty information.
     * @param  _salePrice    The sale price of the NFT asset specified by
     *                       _tokenId.
     *
     * @return receiver      Address of who should be sent the royalty payment.
     * @return royaltyAmount The royalty payment amount for _salePrice.
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        // Put the royalty info on the stack for more efficient access.
        RoyaltyInfo storage info = ERC721ContractMetadataStorage
            .layout()
            ._royaltyInfo;

        // Set the royalty amount to the sale price times the royalty basis
        // points divided by 10_000.
        royaltyAmount = (_salePrice * info.royaltyBps) / 10_000;

        // Set the receiver of the royalty.
        receiver = info.royaltyAddress;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == 0x49064906 || // ERC-4906
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721SeaDropUpgradeable } from "./ERC721SeaDropUpgradeable.sol";
import {
    ERC721ContractMetadataUpgradeable
} from "./ERC721ContractMetadataUpgradeable.sol";

library ERC721SeaDropStorage {
    struct Layout {
        /// @notice Track the allowed SeaDrop addresses.
        mapping(address => bool) _allowedSeaDrop;
        /// @notice Track the enumerated allowed SeaDrop addresses.
        address[] _enumeratedAllowedSeaDrop;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzepplin.contracts.storage.ERC721SeaDrop");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ISeaDropTokenContractMetadataUpgradeable
} from "./ISeaDropTokenContractMetadataUpgradeable.sol";

import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "../lib/SeaDropStructsUpgradeable.sol";

interface INonFungibleSeaDropTokenUpgradeable is
    ISeaDropTokenContractMetadataUpgradeable
{
    /**
     * @dev Revert with an error if a contract is not an allowed
     *      SeaDrop address.
     */
    error OnlyAllowedSeaDrop();

    /**
     * @dev Emit an event when allowed SeaDrop contracts are updated.
     */
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity) external;

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );

    /**
     * @notice Update the public drop data for this nft contract on
     *         SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external;

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external;

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator, when present, must first set `feeBps`.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external;

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external;

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external;

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters
     *                                   to enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
  AllowListData,
  PublicDrop,
  SignedMintValidationParams,
  TokenGatedDropStage
} from "./SeaDropStructsUpgradeable.sol";

interface ERC721SeaDropStructsErrorsAndEventsUpgradeable {
  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

  /**
   * @notice Revert with an error if the number of token gated 
   *         allowedNftTokens doesn't match the length of supplied
   *         drop stages.
   */
  error TokenGatedMismatch();

  /**
   *  @notice Revert with an error if the number of signers doesn't match
   *          the length of supplied signedMintValidationParams
   */
  error SignersMismatch();

  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();

  /**
   * @notice A struct to configure multiple contract options at a time.
   */
  struct MultiConfigureStruct {
    uint256 maxSupply;
    string baseURI;
    string contractURI;
    address seaDropImpl;
    PublicDrop publicDrop;
    string dropURI;
    AllowListData allowListData;
    address creatorPayoutAddress;
    bytes32 provenanceHash;

    address[] allowedFeeRecipients;
    address[] disallowedFeeRecipients;

    address[] allowedPayers;
    address[] disallowedPayers;

    // Token-gated
    address[] tokenGatedAllowedNftTokens;
    TokenGatedDropStage[] tokenGatedDropStages;
    address[] disallowedTokenGatedAllowedNftTokens;

    // Server-signed
    address[] signers;
    SignedMintValidationParams[] signedMintValidationParams;
    address[] disallowedSigners;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import { ReentrancyGuardStorage } from "./ReentrancyGuardStorage.sol";
import "../../../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuardUpgradeable is Initializable {
    using ReentrancyGuardStorage for ReentrancyGuardStorage.Layout;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage.layout().locked = 1;
    }

    modifier nonReentrant() virtual {
        require(ReentrancyGuardStorage.layout().locked == 1, "REENTRANCY");

        ReentrancyGuardStorage.layout().locked = 2;

        _;

        ReentrancyGuardStorage.layout().locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { OperatorFiltererUpgradeable } from "./OperatorFiltererUpgradeable.sol";
import { CANONICAL_CORI_SUBSCRIPTION } from "../lib/Constants.sol";

/**
 * @title  DefaultOperatorFiltererUpgradeable
 * @notice Inherits from OperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 */
abstract contract DefaultOperatorFiltererUpgradeable is
    OperatorFiltererUpgradeable
{
    /// @dev The upgradeable initialize function that should be called when the contract is being deployed.
    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            CANONICAL_CORI_SUBSCRIPTION,
            true
        );
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
pragma solidity 0.8.17;

import {
    IERC2981Upgradeable
} from "../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

interface ISeaDropTokenContractMetadataUpgradeable is IERC2981Upgradeable {
    /**
     * @notice Throw if the max supply exceeds uint64, a limit
     *         due to the storage of bit-packed variables in ERC721A.
     */
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    /**
     * @dev Revert with an error when attempting to set the provenance
     *      hash after the mint has started.
     */
    error ProvenanceHashCannotBeSetAfterMintStarted();

    /**
     * @dev Revert if the royalty basis points is greater than 10_000.
     */
    error InvalidRoyaltyBasisPoints(uint256 basisPoints);

    /**
     * @dev Revert if the royalty address is being set to the zero address.
     */
    error RoyaltyAddressCannotBeZeroAddress();

    /**
     * @dev Emit an event for token metadata reveals/updates,
     *      according to EIP-4906.
     *
     * @param _fromTokenId The start token id.
     * @param _toTokenId   The end token id.
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Emit an event when the URI for the collection-level metadata
     *      is updated.
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emit an event with the previous and new provenance hash after
     *      being updated.
     */
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);

    /**
     * @dev Emit an event when the royalties info is updated.
     */
    event RoyaltyInfoUpdated(address receiver, uint256 bps);

    /**
     * @notice A struct defining royalty info for the contract.
     */
    struct RoyaltyInfo {
        address royaltyAddress;
        uint96 royaltyBps;
    }

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param tokenURI The new base URI to set.
     */
    function setBaseURI(string calldata tokenURI) external;

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external;

    /**
     * @notice Sets the max supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external;

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /**
     * @notice Sets the address and basis points for royalties.
     *
     * @param newInfo The struct to configure royalties.
     */
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external;

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the contract URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view returns (bytes32);

    /**
     * @notice Returns the address that receives royalties.
     */
    function royaltyAddress() external view returns (address);

    /**
     * @notice Returns the royalty basis points out of 10_000.
     */
    function royaltyBasisPoints() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {
    ConstructorInitializableUpgradeable
} from "./ConstructorInitializableUpgradeable.sol";
import { TwoStepOwnableStorage } from "./TwoStepOwnableStorage.sol";
import "../../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
@notice A two-step extension of Ownable, where the new owner must claim ownership of the contract after owner initiates transfer
Owner can cancel the transfer at any point before the new owner claims ownership.
Helpful in guarding against transferring ownership to an address that is unable to act as the Owner.
*/
abstract contract TwoStepOwnableUpgradeable is
    Initializable,
    ConstructorInitializableUpgradeable
{
    using TwoStepOwnableStorage for TwoStepOwnableStorage.Layout;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event PotentialOwnerUpdated(address newPotentialAdministrator);

    error NewOwnerIsZeroAddress();
    error NotNextOwner();
    error OnlyOwner();

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function __TwoStepOwnable_init() internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
    }

    function __TwoStepOwnable_init_unchained() internal onlyInitializing {
        _initialize();
    }

    function _initialize() private onlyConstructor {
        _transferOwnership(msg.sender);
    }

    ///@notice Initiate ownership transfer to newPotentialOwner. Note: new owner will have to manually acceptOwnership
    ///@param newPotentialOwner address of potential new owner
    function transferOwnership(
        address newPotentialOwner
    ) public virtual onlyOwner {
        if (newPotentialOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        TwoStepOwnableStorage.layout().potentialOwner = newPotentialOwner;
        emit PotentialOwnerUpdated(newPotentialOwner);
    }

    ///@notice Claim ownership of smart contract, after the current owner has initiated the process with transferOwnership
    function acceptOwnership() public virtual {
        address _potentialOwner = TwoStepOwnableStorage.layout().potentialOwner;
        if (msg.sender != _potentialOwner) {
            revert NotNextOwner();
        }
        delete TwoStepOwnableStorage.layout().potentialOwner;
        emit PotentialOwnerUpdated(address(0));
        _transferOwnership(_potentialOwner);
    }

    ///@notice cancel ownership transfer
    function cancelOwnershipTransfer() public virtual onlyOwner {
        delete TwoStepOwnableStorage.layout().potentialOwner;
        emit PotentialOwnerUpdated(address(0));
    }

    function owner() public view virtual returns (address) {
        return TwoStepOwnableStorage.layout()._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (TwoStepOwnableStorage.layout()._owner != msg.sender) {
            revert OnlyOwner();
        }
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
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = TwoStepOwnableStorage.layout()._owner;
        TwoStepOwnableStorage.layout()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
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
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

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
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
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
        return ERC721AStorage.layout()._currentIndex;
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
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
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
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
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
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
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
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
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

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
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
        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
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
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
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
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage.layout()._tokenApprovals[tokenId];
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
    ) public virtual override {
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
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
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
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
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
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
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
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
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

            ERC721AStorage.layout()._currentIndex = end;
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
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
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
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
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
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
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
            ERC721AStorage.layout()._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "../../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @author emo.eth
 * @notice Abstract smart contract that provides an onlyUninitialized modifier which only allows calling when
 *         from within a constructor of some sort, whether directly instantiating an inherting contract,
 *         or when delegatecalling from a proxy
 */
abstract contract ConstructorInitializableUpgradeable is Initializable {
    function __ConstructorInitializable_init() internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
    }

    function __ConstructorInitializable_init_unchained()
        internal
        onlyInitializing
    {}

    error AlreadyInitialized();

    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert AlreadyInitialized();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { TwoStepOwnableUpgradeable } from "./TwoStepOwnableUpgradeable.sol";

library TwoStepOwnableStorage {

  struct Layout {
    address _owner;

    address potentialOwner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.TwoStepOwnable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
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
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructor()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
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
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    ) external;

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
    function approve(address to, uint256 tokenId) external;

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PublicDrop, TokenGatedDropStage, SignedMintValidationParams } from "./SeaDropStructsUpgradeable.sol";

interface SeaDropErrorsAndEventsUpgradeable {
    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Revert with an error if the mint quantity is zero.
     */
    error MintQuantityCannotBeZero();

    /**
     * @dev Revert with an error if the mint quantity exceeds the max allowed
     *      to be minted per wallet.
     */
    error MintQuantityExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply.
     */
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply for the stage.
     *      Note: The `maxTokenSupplyForStage` for public mint is
     *      always `type(uint).max`.
     */
    error MintQuantityExceedsMaxTokenSupplyForStage(
        uint256 total, 
        uint256 maxTokenSupplyForStage
    );
    
    /**
     * @dev Revert if the fee recipient is the zero address.
     */
    error FeeRecipientCannotBeZeroAddress();

    /**
     * @dev Revert if the fee recipient is not already included.
     */
    error FeeRecipientNotPresent();

    /**
     * @dev Revert if the fee basis points is greater than 10_000.
     */
     error InvalidFeeBps(uint256 feeBps);

    /**
     * @dev Revert if the fee recipient is already included.
     */
    error DuplicateFeeRecipient();

    /**
     * @dev Revert if the fee recipient is restricted and not allowed.
     */
    error FeeRecipientNotAllowed();

    /**
     * @dev Revert if the creator payout address is the zero address.
     */
    error CreatorPayoutAddressCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPayment(uint256 got, uint256 want);

    /**
     * @dev Revert with an error if the allow list proof is invalid.
     */
    error InvalidProof();

    /**
     * @dev Revert if a supplied signer address is the zero address.
     */
    error SignerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if signer's signature is invalid.
     */
    error InvalidSignature(address recoveredSigner);

    /**
     * @dev Revert with an error if a signer is not included in
     *      the enumeration when removing.
     */
    error SignerNotPresent();

    /**
     * @dev Revert with an error if a payer is not included in
     *      the enumeration when removing.
     */
    error PayerNotPresent();

    /**
     * @dev Revert with an error if a payer is already included in mapping
     *      when adding.
     *      Note: only applies when adding a single payer, as duplicates in
     *      enumeration can be removed with updatePayer.
     */
    error DuplicatePayer();

    /**
     * @dev Revert with an error if the payer is not allowed. The minter must
     *      pay for their own mint.
     */
    error PayerNotAllowed();

    /**
     * @dev Revert if a supplied payer address is the zero address.
     */
    error PayerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the sender does not
     *      match the INonFungibleSeaDropToken interface.
     */
    error OnlyINonFungibleSeaDropToken(address sender);

    /**
     * @dev Revert with an error if the sender of a token gated supplied
     *      drop stage redeem is not the owner of the token.
     */
    error TokenGatedNotTokenOwner(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    );

    /**
     * @dev Revert with an error if the token id has already been used to
     *      redeem a token gated drop stage.
     */
    error TokenGatedTokenIdAlreadyRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    );

    /**
     * @dev Revert with an error if an empty TokenGatedDropStage is provided
     *      for an already-empty TokenGatedDropStage.
     */
     error TokenGatedDropStageNotPresent();

    /**
     * @dev Revert with an error if an allowedNftToken is set to
     *      the zero address.
     */
     error TokenGatedDropAllowedNftTokenCannotBeZeroAddress();

    /**
     * @dev Revert with an error if an allowedNftToken is set to
     *      the drop token itself.
     */
     error TokenGatedDropAllowedNftTokenCannotBeDropToken();


    /**
     * @dev Revert with an error if supplied signed mint price is less than
     *      the minimum specified.
     */
    error InvalidSignedMintPrice(uint256 got, uint256 minimum);

    /**
     * @dev Revert with an error if supplied signed maxTotalMintableByWallet
     *      is greater than the maximum specified.
     */
    error InvalidSignedMaxTotalMintableByWallet(uint256 got, uint256 maximum);

    /**
     * @dev Revert with an error if supplied signed start time is less than
     *      the minimum specified.
     */
    error InvalidSignedStartTime(uint256 got, uint256 minimum);
    
    /**
     * @dev Revert with an error if supplied signed end time is greater than
     *      the maximum specified.
     */
    error InvalidSignedEndTime(uint256 got, uint256 maximum);

    /**
     * @dev Revert with an error if supplied signed maxTokenSupplyForStage
     *      is greater than the maximum specified.
     */
     error InvalidSignedMaxTokenSupplyForStage(uint256 got, uint256 maximum);
    
     /**
     * @dev Revert with an error if supplied signed feeBps is greater than
     *      the maximum specified, or less than the minimum.
     */
    error InvalidSignedFeeBps(uint256 got, uint256 minimumOrMaximum);

    /**
     * @dev Revert with an error if signed mint did not specify to restrict
     *      fee recipients.
     */
    error SignedMintsMustRestrictFeeRecipients();

    /**
     * @dev Revert with an error if a signature for a signed mint has already
     *      been used.
     */
    error SignatureAlreadyUsed();

    /**
     * @dev An event with details of a SeaDrop mint, for analytical purposes.
     * 
     * @param nftContract    The nft contract.
     * @param minter         The mint recipient.
     * @param feeRecipient   The fee recipient.
     * @param payer          The address who payed for the tx.
     * @param quantityMinted The number of tokens minted.
     * @param unitMintPrice  The amount paid for each token.
     * @param feeBps         The fee out of 10_000 basis points collected.
     * @param dropStageIndex The drop stage index. Items minted
     *                       through mintPublic() have
     *                       dropStageIndex of 0.
     */
    event SeaDropMint(
        address indexed nftContract,
        address indexed minter,
        address indexed feeRecipient,
        address payer,
        uint256 quantityMinted,
        uint256 unitMintPrice,
        uint256 feeBps,
        uint256 dropStageIndex
    );

    /**
     * @dev An event with updated public drop data for an nft contract.
     */
    event PublicDropUpdated(
        address indexed nftContract,
        PublicDrop publicDrop
    );

    /**
     * @dev An event with updated token gated drop stage data
     *      for an nft contract.
     */
    event TokenGatedDropStageUpdated(
        address indexed nftContract,
        address indexed allowedNftToken,
        TokenGatedDropStage dropStage
    );

    /**
     * @dev An event with updated allow list data for an nft contract.
     * 
     * @param nftContract        The nft contract.
     * @param previousMerkleRoot The previous allow list merkle root.
     * @param newMerkleRoot      The new allow list merkle root.
     * @param publicKeyURI       If the allow list is encrypted, the public key
     *                           URIs that can decrypt the list.
     *                           Empty if unencrypted.
     * @param allowListURI       The URI for the allow list.
     */
    event AllowListUpdated(
        address indexed nftContract,
        bytes32 indexed previousMerkleRoot,
        bytes32 indexed newMerkleRoot,
        string[] publicKeyURI,
        string allowListURI
    );

    /**
     * @dev An event with updated drop URI for an nft contract.
     */
    event DropURIUpdated(address indexed nftContract, string newDropURI);

    /**
     * @dev An event with the updated creator payout address for an nft
     *      contract.
     */
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );

    /**
     * @dev An event with the updated allowed fee recipient for an nft
     *      contract.
     */
    event AllowedFeeRecipientUpdated(
        address indexed nftContract,
        address indexed feeRecipient,
        bool indexed allowed
    );

    /**
     * @dev An event with the updated validation parameters for server-side
     *      signers.
     */
    event SignedMintValidationParamsUpdated(
        address indexed nftContract,
        address indexed signer,
        SignedMintValidationParams signedMintValidationParams
    );   

    /**
     * @dev An event with the updated payer for an nft contract.
     */
    event PayerUpdated(
        address indexed nftContract,
        address indexed payer,
        bool indexed allowed
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ReentrancyGuardUpgradeable } from "./ReentrancyGuardUpgradeable.sol";

library ReentrancyGuardStorage {

  struct Layout {
    uint256 locked;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.ReentrancyGuard');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IOperatorFilterRegistry } from "../IOperatorFilterRegistry.sol";
import {
    Initializable
} from "../../../../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry when the init function is called.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    /// @notice Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(
                            address(this),
                            subscriptionOrRegistrantToCopy
                        );
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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