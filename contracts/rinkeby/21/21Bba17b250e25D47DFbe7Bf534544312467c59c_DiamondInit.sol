// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Initialiser contract authored by Sibling Labs
 * Version 0.3.0
 * 
 * This initialiser contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Sibling Labs
/**************************************************************/

import { GlobalState } from "./libraries/GlobalState.sol";
import { AllowlistLib } from "./libraries/AllowlistLib.sol";
import { CentreFacetLib } from "./libraries/CentreFacetLib.sol";
import { ERC165Lib } from "./libraries/ERC165Lib.sol";
import { PrivSaleLib } from "./libraries/PrivSaleLib.sol";
import { RoyaltiesConfigLib } from "./libraries/RoyaltiesConfigLib.sol";

contract DiamondInit {

    function initAll() public {
        initAdminPrivilegesFacet();
        initAllowlistFacet();
        initCentreFacet();
        initERC165Facet();
        initERC721AFacet();
        initPaymentSplitterFacet();
        initPrivSaleFacet();
        initRoyaltiesConfigFacet();
    }

    // AdminPrivilegesFacet //

    address[] private admins = [0x699a1928EA12D21dd2138F36A3690059bf1253A0];

    function initAdminPrivilegesFacet() public {
        for (uint256 i; i < admins.length; i++) {
            GlobalState.getState().admins[admins[i]] = true;
        }
    }

    // AllowlistFacet //

    bytes32 private constant merkleRoot = 0x3d7ea9207f8fd37c25e5eebfea71390f9fefee8c47f9b9a5c390cdee08df7ba2;

    function initAllowlistFacet() public {
        AllowlistLib.getState().merkleRoot = merkleRoot;
    }

    // CentreFacet //

    address private constant ERC721AFacet = 0x67b85b3564d4a1FD29d82dDd99f96761c25A4949; // rinkeby

    function initCentreFacet() public {
        CentreFacetLib.state storage s = CentreFacetLib.getState();

        s.ERC721AFacet = ERC721AFacet;
        s.maxSupply = 10000;
        s.walletCap = [5, 20];
        s.price = [0.01 ether, 0.01 ether];
        s.baseURI = "https://gateway.pinata.cloud/ipfs/.../?";
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;
    bytes4 private constant ID_IERC2981 = 0x2a55205a;
    bytes4 private constant ID_IERC721 = 0x80ac58cd;
    bytes4 private constant ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;
        s.supportedInterfaces[ID_IERC2981] = true;
        s.supportedInterfaces[ID_IERC721] = true;
        s.supportedInterfaces[ID_IERC721METADATA] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // ERC721AFacet //

    string private constant name = "MyToken";
    string private constant symbol = "MTK";

    function initERC721AFacet() public {
        bytes memory callData = abi.encodeWithSignature("initialiseERC721A(string,string)", name, symbol);
        (bool success, ) = ERC721AFacet.delegatecall(callData);
        require(success, "Initialising ERC721AFacet Failed");
    }

    // PaymentSplitterFacet //

    address private constant PaymentSplitterFacet = 0xABe0f9b11D95186208227A112CC6c08a6b093341; // rinkeby

    address[] private payees = [0x699a1928EA12D21dd2138F36A3690059bf1253A0];
    uint256[] private shares = [10000];

    function initPaymentSplitterFacet() public {
        bytes memory callData = abi.encodeWithSignature(
            "initialisePaymentSplitterFacet(address[],uint256[])",
            payees,
            shares
        );
        (bool success, ) = PaymentSplitterFacet.delegatecall(callData);
        require(success, "Initialising PaymentSplitterFacet Failed");
    }

    // PrivSaleFacet //

    uint256 private constant privSaleTimestamp = 1663286400;
    uint256 private constant privSaleLength = 86400;

    function initPrivSaleFacet() public {
        PrivSaleLib.state storage s = PrivSaleLib.getState();

        s.saleTimestamp = privSaleTimestamp;
        s.privSaleLength = privSaleLength;
    }

    // RoyaltiesConfigFacet //

    address payable private constant royaltyRecipient = payable(0x699a1928EA12D21dd2138F36A3690059bf1253A0);
    uint256 private constant royaltyBps = 10000;

    function initRoyaltiesConfigFacet() public {
        RoyaltiesConfigLib.state storage s = RoyaltiesConfigLib.getState();

        s.royaltyRecipient = royaltyRecipient;
        s.royaltyBps = royaltyBps;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Global Storage Library for NFT Smart Contracts
 * Authored by Sibling Labs
 * Version 0.2.1
 * 
 * This library is designed to provide diamond storage and
 * shared functionality to all facets of a diamond used for an
 * NFT collection.
/**************************************************************/

library GlobalState {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("globalstate.storage");

    struct state {
        address owner;
        mapping(address => bool) admins;

        bool paused;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // GLOBAL FUNCTIONS //

    /**
    * @dev Returns true if provided address is an admin or the
    *      contract owner.
    */
    function isAdmin(address _addr) internal view returns (bool) {
        state storage s = getState();
        return s.owner == _addr || s.admins[_addr];
    }

    /**
    * @dev Reverts if caller is not an admin or contract owner.
    */
    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "GlobalState: caller is not admin or owner");
    }

    /**
    * @dev Reverts if contract is paused.
    */
    function requireContractIsNotPaused() internal view {
        require(!getState().paused || isAdmin(msg.sender), "GlobalState: contract is paused");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AllowlistLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * AllowlistFacet - it facilitates diamond storage and shared
 * functionality associated with AllowlistFacet.
/**************************************************************/

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library AllowlistLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("allowlistlibrary.storage");

    struct state {
        bytes32 merkleRoot;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
    * @dev Verify that provided merkle proof & leaf node
    *      combination belong to the stored merkle root.
    */
    function validateProof(bytes32[] calldata proof, address leaf) internal view returns (bool) {
        return MerkleProof.verify(
            proof,
            getState().merkleRoot,
            keccak256(abi.encodePacked(leaf))
        );
    }

    /**
    * @dev Require that the caller and the provided merkle proof
    *      belong to the stored merkle root.
    */
    function requireValidProof(bytes32[] calldata proof) internal view {
        require(validateProof(proof, msg.sender), "AllowlistFacet: invalid merkle proof");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * CentreFacetLib authored by Sibling Labs
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * CentreFacet - it facilitates diamond storage and shared
 * functionality associated with CentreFacet.
/**************************************************************/

import "erc721a-upgradeable/contracts/ERC721AStorage.sol";

library CentreFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    struct state {
        uint256 maxSupply;
        uint256[] walletCap;
        uint256[] price;
        string baseURI;
        bool burnStatus;

        address ERC721AFacet;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        uint256 _BITPOS_NUMBER_MINTED = 64;
        uint256 _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        uint256 startTokenId = 0;

        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - startTokenId;
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        uint256 _BITMASK_BURNED = 1 << 224;
        uint256 startTokenId = 0;
        
        return
            startTokenId <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

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
pragma solidity ^0.8.0;

/**************************************************************\
 * ERC165Lib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * ERC165Facet - it facilitates diamond storage and shared
 * functionality associated with ERC165Facet.
/**************************************************************/

library ERC165Lib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("erc165.storage");

    struct state {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * PrivSaleLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * PrivSaleFacet - it facilitates diamond storage and shared
 * functionality associated with PrivSaleFacet.
/**************************************************************/

library PrivSaleLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("privsaleperiodlibrary.storage");

    struct state {
        uint256 privSaleLength;
        uint256 saleTimestamp;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
    * @dev Returns a boolean indicating whether the private sale
    *      phase is currently active.
    */
    function isPrivSaleActive() internal view returns (bool) {
        state storage s = getState();
        return
            s.saleTimestamp != 0 &&
            block.timestamp >= s.saleTimestamp &&
            block.timestamp < s.saleTimestamp + s.privSaleLength;
    }

    /**
    * @dev Returns whether the public sale is currently
    *      active.
    */
    function isPublicSaleActive() internal view returns (bool) {
        state storage s = getState();
        return s.saleTimestamp != 0 && block.timestamp >= s.saleTimestamp + s.privSaleLength;
    }

    /**
    * @dev Reverts if the private sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      private sale.
    */
    function requirePrivSaleIsActive() internal view {
        require(isPrivSaleActive(), "PrivSalePeriodFacet: private sale is not active now");
    }

    /**
    * @dev Reverts if the public sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      public sale.
    */
    function requirePublicSaleIsActive() internal view {
        require(isPublicSaleActive(), "PrivSalePeriodFacet: public sale is not active now");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * RoyaltiesConfigLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * RoyaltiesConfigFacet - it facilitates diamond storage and shared
 * functionality associated with RoyaltiesConfigFacet.
/**************************************************************/

library RoyaltiesConfigLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("royaltiesconfiglibrary.storage");

    struct state {
        uint256 royaltyBps;
        address payable royaltyRecipient;
    }

    /**
     * @dev Return stored state struct.
     */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
     * @dev Returns royalty payee and amount for tokens in this
     *      collection. Adheres to EIP-2981.
     */
    function royaltyInfo(uint256, uint256 value) internal view returns (address, uint256) {
        state storage s = getState();
        return (s.royaltyRecipient, value * s.royaltyBps / 10000);
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

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Reference type for token approval.
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