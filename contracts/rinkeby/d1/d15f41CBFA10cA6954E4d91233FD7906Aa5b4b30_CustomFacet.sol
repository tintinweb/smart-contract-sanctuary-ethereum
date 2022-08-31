// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AdminPauseFacet authored by Sibling Labs
 * Version 0.2.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";
import { TokenFacetLib } from "../libraries/TokenFacetLib.sol";

import { PrivSaleLib } from "../libraries/PrivSaleLib.sol";
import { AllowlistLib } from "../libraries/AllowlistLib.sol";
import { RoyaltiesConfigLib } from "../libraries/RoyaltiesConfigLib.sol";

contract CustomFacet {
    address public ERC721A = 0x9B049d3a78DDf7246bd8265703DFbc24bca9ca8e; // Instance of ERC721AUpgradeable on Rinkeby

    function CustomFacet_SetERC721A(address addr) public {
        GlobalState.requireCallerIsAdmin();
        ERC721A = addr;
    }

    // VARIABLE GETTERS //

    function maxSupply() public view returns (uint256) {
        return TokenFacetLib.getState().maxSupply;
    }

    function walletCapAL() public view returns (uint256) {
        return TokenFacetLib.getState().walletCap[0];
    }

    function walletCap() public view returns (uint256) {
        return TokenFacetLib.getState().walletCap[1];
    }

    function priceAL() public view returns (uint256) {
        return TokenFacetLib.getState().price[0];
    }

    function price() public view returns (uint256) {
        return TokenFacetLib.getState().price[1];
    }

    function burnStatus() public view returns (bool) {
        return TokenFacetLib.getState().burnStatus;
    }

    // SETUP & ADMIN FUNCTIONS //

    function setPrices(uint256 _price, uint256 _priceAL) public {
        GlobalState.requireCallerIsAdmin();

        TokenFacetLib.getState().price[0] = _priceAL;
        TokenFacetLib.getState().price[1] = _price;
    }

    function setWalletCaps(uint256 _walletCap, uint256 _walletCapAL) public {
        GlobalState.requireCallerIsAdmin();

        TokenFacetLib.getState().walletCap[0] = _walletCapAL;
        TokenFacetLib.getState().walletCap[1] = _walletCap;
    }

    function toggleBurnStatus() public {
        GlobalState.requireCallerIsAdmin();

        TokenFacetLib.getState().burnStatus = !TokenFacetLib.getState().burnStatus;
    }

    function setBaseURI(string memory URI) public {
        GlobalState.requireCallerIsAdmin();

        TokenFacetLib.getState().baseURI = URI;
    }

    function reserve(uint256 amount) public {
        GlobalState.requireCallerIsAdmin();

        safeMint(msg.sender, amount);
    }

    // PUBLIC FUNCTIONS //

    function mint(uint256 amount, bytes32[] calldata _merkleProof) public payable {
        GlobalState.requireContractIsNotPaused();
        require(PrivSaleLib.getState().saleTimestamp > 0, "Sale has not begun");

        bool al = PrivSaleLib.isPrivSaleActive();
        if (al) AllowlistLib.requireValidProof(_merkleProof);

        TokenFacetLib.state storage s = TokenFacetLib.getState();

        uint256 _price = al ? s.price[0] : s.price[1];
        require(msg.value == _price * amount, "Incorrect amount of Ether sent");

        uint256 _walletCap = al ? s.walletCap[0] : s.walletCap[1];
        require(
            amount + _numberMinted(msg.sender) <= _walletCap,
            string(
                abi.encodePacked(
                    "Maximum tokens per wallet during ",
                    al ? "private" : "public",
                    " sale is ",
                    TokenFacetLib._toString(_walletCap)
                )
            )
        );

        safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) public {
        GlobalState.requireContractIsNotPaused();
        require(TokenFacetLib.getState().burnStatus, "Token burning is not available now");

        (bool success, ) = ERC721A.delegatecall(
            abi.encodeWithSignature("_burn(uint256,bool)", tokenId, true)
        );
        require(success, "E1");
    }

    // METADATA & MISC FUNCTIONS //

    function _numberMinted(address account) internal returns (uint256) {
        address addr = ERC721A;
        bytes memory sig = abi.encodeWithSignature("_numberMinted(address)", account);

        assembly {
            let result := delegatecall(gas(), addr, add(sig, 0x20), mload(sig), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function totalSupply() internal returns (uint256) {
        address addr = ERC721A;
        bytes memory sig = abi.encodeWithSignature("totalSupply()");

        assembly {
            let result := delegatecall(gas(), addr, add(sig, 0x20), mload(sig), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function safeMint(address to, uint256 amount) internal {
        require(totalSupply() + amount <= TokenFacetLib.getState().maxSupply, "Too few tokens remaining");

        (bool success, ) = ERC721A.delegatecall(
            abi.encodeWithSignature("_safeMint(address,uint256)", to, amount)
        );
        require(success, "E1");
    }

    function _baseURI() internal view returns (string memory) {
        return TokenFacetLib.getState().baseURI;
    }

    fallback() external {
        address facet = ERC721A;
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Global Storage Library for NFT Smart Contracts
 * Authored by Sibling Labs
 * Version 0.2.0
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
        state storage ds = getState();
        return ds.owner == _addr || ds.admins[_addr];
    }

    /**
    * @dev Reverts if caller is not an admin or contract owner.
    */
    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "GlobalState: caller must be an admin");
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
 * TokenFacetLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * TokenFacet - it facilitates diamond storage and shared
 * functionality associated with TokenFacet.
/**************************************************************/

library TokenFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    struct state {
        uint256 maxSupply;
        uint256[] walletCap;
        uint256[] price;
        string baseURI;
        bool burnStatus;
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