// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { Modifiers } from "../libraries/LibDiamond.sol";
import { LibERC721, StorageLayout } from "../libraries/LibERC721.sol";
import { LibSaleManager, SaleStorage, SaleConfig, MintParams } from "../libraries/LibSaleManager.sol";
import { LibTraitManager } from "../libraries/LibTraitManager.sol";
import { LibUtils } from "../libraries/LibUtils.sol";

// solhint-disable avoid-tx-origin, reason-string
contract SaleManager is Modifiers {
  event Minted(uint256 indexed saleId, address indexed minter, uint256 indexed quantity);

  /**
   * @notice Validates the minting process by ensuring that the buyer has enough funds,
   *         the max supply of contract and current sale is not exceeded, and the user's maximum per-transaction and
   *         per-wallet limits are not exceeded.
   * @param params see struct MintParams in /libraries/LibSaleManager.sol
   */
  modifier validateMint(MintParams calldata params) {
    address sender = LibUtils.msgSender();
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    SaleConfig memory currentSale = saleStorage.sales[params.saleId];

    require(currentSale.active, "SaleManager: Sale not active");
    require(msg.value >= currentSale.price * params.quantity, "SaleManager: Not enough funds");
    require(params.quantity <= currentSale.maxPerTx, "SaleManager: Transaction limit exceeded");
    require(saleStorage.addressSaleMints[sender][params.saleId] + params.quantity <= currentSale.maxPerWallet, "SaleManager: Wallet limit exceeded");
    require(currentSale.supply + params.quantity <= currentSale.maxSupply, "SaleManager: Sale supply exceeded");
    require(LibERC721.totalSupply() + params.quantity <= LibERC721.getStorage().maxSupply, "SaleManager: Collection supply exceeded");

    if (currentSale.merkleRoot != bytes32(0)) verifyMerkle(sender, params.proof, currentSale.merkleRoot);
    if (!saleStorage.allowContractsMint && sender != tx.origin) revert("SaleManager: Contracts not allowed to mint");
    _;
  }

  modifier seedCheck(uint256 seeds) {
    require(seeds >= LibTraitManager.getLayerStorage().layerCount, "SaleManager: Not enough seeds");
    _;
  }

  /// @notice modifier to check if sale exist before interacting
  modifier saleExist(uint16 id) {
    require(getSale(id).maxSupply > 0, "SaleManager: Sale doesnt exist");
    _;
  }

  function verifyMerkle(address sender, bytes32[] calldata proof, bytes32 merkleRoot) internal pure {
    bool verify = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(sender)));
    require(verify, "SaleManager: Not whitelisted");
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                        MINT FUNCTIONS
  //
  ////////////////////////////////////////////////////////////////////

  function mintToken(MintParams calldata params) public payable seedCheck(params.seeds.length) validateMint(params) {
    require(getSale(params.saleId).maxSupply > 0, "SaleManager: Sale doesnt exist");
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    address sender = LibUtils.msgSender();

    generateTokens(params.quantity, params.seeds);
    LibERC721._safeMint(sender, params.quantity);

    unchecked {
      saleStorage.sales[params.saleId].supply += params.quantity;
      saleStorage.addressSaleMints[sender][params.saleId] += params.quantity;
    }

    emit Minted(params.saleId, sender, params.quantity);
  }

  function mintOwner(address to, uint16 quantity, uint16[] calldata seeds) public seedCheck(seeds.length) onlyOwner {
    StorageLayout storage ds = LibERC721.getStorage();
    require(LibERC721.totalSupply() + quantity <= ds.maxSupply, "SaleManager: Collection supply exceeded");
    require(ds.creatorSupply + quantity <= ds.creatorMaxSupply, "SaleManager: Creator supply exceeded");

    generateTokens(quantity, seeds);
    LibERC721._safeMint(to, quantity);

    unchecked {
      ds.creatorSupply += quantity;
    }
  }

  function generateTokens(uint16 quantity, uint16[] calldata seeds) internal {
    uint16 nextTokenId = uint16(LibERC721.nextTokenId());

    if (quantity > 1) {
      LibTraitManager.createMultiple(nextTokenId, quantity, seeds);
    } else if (quantity == 1) {
      LibTraitManager.createToken(nextTokenId, seeds);
    }
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                        SALE MANAGEMENT
  //
  ////////////////////////////////////////////////////////////////////

  function createTestSale() public onlyOwner {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();

    uint256 _totalSupply = activeSupply() + 5000;
    require(_totalSupply <= LibERC721.getStorage().maxSupply, "SaleManager: Max supply exceeded");

    saleStorage.sales[saleStorage.saleCount++] = SaleConfig({
      id: saleStorage.saleCount,
      merkleRoot: bytes32(0),
      active: true,
      price: 0,
      maxPerTx: 100,
      maxPerWallet: 500,
      maxSupply: 5000,
      supply: 0
    });
  }

  function createPublicSale(bool _saleActive, uint256 _salePrice, uint16 _maxPerTx, uint16 _maxPerWallet, uint16 _maxSupply) public onlyOwner {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();

    uint256 _totalSupply = activeSupply() + _maxSupply;
    require(_totalSupply <= LibERC721.getStorage().maxSupply, "SaleManager: Max supply exceeded");

    saleStorage.sales[saleStorage.saleCount++] = SaleConfig({
      id: saleStorage.saleCount,
      merkleRoot: bytes32(0),
      active: _saleActive,
      price: _salePrice,
      maxPerTx: _maxPerTx,
      maxPerWallet: _maxPerWallet,
      maxSupply: _maxSupply,
      supply: 0
    });
  }

  function createWhitelistSale(
    bytes32 _merkleRoot,
    bool _saleActive,
    uint256 _salePrice,
    uint16 _maxPerTx,
    uint16 _maxPerWallet,
    uint16 _maxSupply
  ) public onlyOwner {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();

    uint256 _totalSupply = activeSupply() + _maxSupply;
    require(_totalSupply <= LibERC721.getStorage().maxSupply, "SaleManager: Max supply exceeded");

    saleStorage.sales[saleStorage.saleCount++] = SaleConfig({
      id: saleStorage.saleCount,
      merkleRoot: _merkleRoot,
      active: _saleActive,
      price: _salePrice,
      maxPerTx: _maxPerTx,
      maxPerWallet: _maxPerWallet,
      maxSupply: _maxSupply,
      supply: 0
    });
  }

  function removeSale(uint16 saleId) public saleExist(saleId) {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    unchecked {
      for (uint16 i = saleId; i < saleStorage.saleCount - 1; i++) {
        saleStorage.sales[i] = saleStorage.sales[i + 1];
        saleStorage.sales[i].id = saleStorage.sales[i + 1].id;
      }

      delete saleStorage.sales[saleStorage.saleCount - 1];
      saleStorage.saleCount--;
    }
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                       STATE SETTERS
  //
  ////////////////////////////////////////////////////////////////////

  /**
   * @notice Set whitelist sale active state.
   * @param status true - enable / false - disable
   * @dev Requirements: Owner
   */
  function setSaleState(uint16 saleId, bool status) public saleExist(saleId) onlyOwner {
    LibSaleManager.getStorage().sales[saleId].active = status;
  }

  /**
   * @notice Set public sale price.
   * @param price price in WEI format
   * @dev Requirements: Owner
   */
  function setSalePrice(uint16 saleId, uint256 price) public saleExist(saleId) onlyOwner {
    LibSaleManager.getStorage().sales[saleId].price = price;
  }

  /**
   * @notice Set public sale limit per transaction.
   * @param maxPerTx Number of tokens per tx
   * @dev Requirements: Owner
   */
  function setSalePerTx(uint16 saleId, uint16 maxPerTx) public saleExist(saleId) onlyOwner {
    LibSaleManager.getStorage().sales[saleId].maxPerTx = maxPerTx;
  }

  /**
   * @notice Set public sale limit per wallet.
   * @param maxPerWallet Number of tokens per wallet
   * @dev Requirements: Owner
   */
  function setSalePerWallet(uint16 saleId, uint16 maxPerWallet) public saleExist(saleId) onlyOwner {
    LibSaleManager.getStorage().sales[saleId].maxPerWallet = maxPerWallet;
  }

  /**
   * @notice Set whitelist max supply.
   * @param supply New supply.
   * @dev Requirements: Owner
   */
  function setSaleMaxSupply(uint16 saleId, uint16 supply) public saleExist(saleId) onlyOwner {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    uint256 currentActiveSupply = activeSupply() - saleStorage.sales[saleId].maxSupply;

    require(supply >= saleStorage.sales[saleId].supply, "SaleManager: New supply too low");
    require(currentActiveSupply + supply <= LibERC721.getStorage().maxSupply, "SaleManager: Collection supply exceeded");

    saleStorage.sales[saleId].maxSupply = supply;
  }

  /**
   * @notice Set whitelist merkle root.
   * @param root New merkle root
   * @dev Requirements: Owner
   */
  function setSaleMerkleRoot(uint16 saleId, bytes32 root) public saleExist(saleId) onlyOwner {
    LibSaleManager.getStorage().sales[saleId].merkleRoot = root;
  }

  /**
   * @notice Allow/Prevent mint from other contracts
   * @param _status true - enable / false - disable
   * @dev Requirements: Owner
   */
  function setAllowContractsMint(bool _status) public onlyOwner {
    LibSaleManager.getStorage().allowContractsMint = _status;
  }

  /**
   * @notice Set contract max supply.
   * @param supply New supply. Must be higher than last supply
   * @dev Requirements: Owner
   */
  function setMaxSupply(uint16 supply) public onlyOwner {
    require(supply >= LibERC721.totalSupply(), "SaleManager: New supply lower than totalSupply");
    require(supply >= activeSupply(), "SaleManager: New supply lower than activeSupply");

    LibERC721.getStorage().maxSupply = supply;
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                       STATE GETTERS
  //
  ////////////////////////////////////////////////////////////////////

  function activeSupply() public view returns (uint256 supply) {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    unchecked {
      for (uint16 i = 0; i < saleStorage.saleCount; ++i) {
        supply += saleStorage.sales[i].maxSupply;
      }
      supply += LibERC721.getStorage().creatorMaxSupply;
    }
  }

  function getSale(uint16 saleId) public view returns (SaleConfig memory) {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();
    require(saleId <= saleStorage.saleCount, "SaleManager: Sale doesnt exist");

    return saleStorage.sales[saleId];
  }

  function getAllSales() public view returns (SaleConfig[] memory) {
    SaleStorage storage saleStorage = LibSaleManager.getStorage();

    unchecked {
      SaleConfig[] memory allSales = new SaleConfig[](saleStorage.saleCount);
      for (uint16 i = 0; i < saleStorage.saleCount; ++i) {
        allSales[i] = saleStorage.sales[i];
      }
      return allSales;
    }
  }

  function saleCount() public view returns (uint256) {
    return LibSaleManager.getStorage().saleCount;
  }

  function addressSaleMints(uint16 saleId, address userAddress) public view returns (uint256) {
    return LibSaleManager.getStorage().addressSaleMints[userAddress][saleId];
  }

  function allowContractsMint() public view returns (bool) {
    return LibSaleManager.getStorage().allowContractsMint;
  }

  function withdrawFunds() public onlyOwner {
    (bool transfer, ) = payable(getContractOwner()).call{ value: address(this).balance }("");
    require(transfer, "SaleManager: Withdraw transfer failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
// solhint-disable reason-string, no-inline-assembly, avoid-low-level-calls

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
  bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else {
        revert("LibDiamondCut: Incorrect FacetCutAction");
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    address oldFacet;
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
      // replace function if it exists, else add new function
      if (oldFacetAddress != address(0)) {
        // cache old address for future clean up
        oldFacet = oldFacetAddress;
        removeFunction(ds, oldFacetAddress, selector);
      }
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
    // clean up non existing functions
    if (ds.facetFunctionSelectors[oldFacet].functionSelectors.length > 0) {
      for (uint256 sId = 0; sId < ds.facetFunctionSelectors[oldFacet].functionSelectors.length; sId++) {
        removeFunction(ds, oldFacet, ds.facetFunctionSelectors[oldFacet].functionSelectors[sId]);
      }
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
    ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
    require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
    // an immutable function is a function defined directly in a diamond
    require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      return;
    }
    enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
    (bool success, bytes memory error) = _init.delegatecall(_calldata);
    if (!success) {
      if (error.length > 0) {
        // bubble up error
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(error)
          revert(add(32, error), returndata_size)
        }
      } else {
        revert InitializationFunctionReverted(_init, _calldata);
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}

contract Modifiers {
  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  function getContractOwner() internal view returns (address) {
    return LibDiamond.contractOwner();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibUtils } from "./LibUtils.sol";

interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

struct TokenApprovalRef {
  address value;
}

struct StorageLayout {
  string name;
  string symbol;
  uint16 maxSupply;
  uint16 creatorSupply;
  uint16 creatorMaxSupply;
  bool burnActive;
  uint256 _currentIndex;
  uint256 _burnCounter;
  mapping(uint256 => uint256) _packedOwnerships;
  mapping(address => uint256) _packedAddressData;
  mapping(uint256 => TokenApprovalRef) _tokenApprovals;
  mapping(address => mapping(address => bool)) _operatorApprovals;
}

//solhint-disable no-inline-assembly, reason-string, no-empty-blocks
library LibERC721 {
  bytes32 internal constant STORAGE_SLOT = keccak256("ERC721A.contracts.storage.ERC721A");
  uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
  uint256 internal constant _BITMASK_BURNED = 1 << 224;
  uint256 internal constant _BITPOS_NUMBER_BURNED = 128;
  uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
  uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;

  function getStorage() internal pure returns (StorageLayout storage strg) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  function _mint(address to, uint256 quantity) internal {
    StorageLayout storage ds = getStorage();
    uint256 startTokenId = ds._currentIndex;

    require(quantity > 0, "LibERC721: Cant mint 0 tokens");
    bytes32 transferEventSig = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 bitMaskAddress = (1 << 160) - 1;
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
      ds._packedAddressData[to] += quantity * ((1 << 64) | 1);

      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      ds._packedOwnerships[startTokenId] = _packOwnershipData(to, _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0));

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      // Use assembly to loop and emit the `Transfer` event for gas savings.
      // The duplicated `log4` removes an extra check and reduces stack juggling.
      // The assembly, together with the surrounding Solidity code, have been
      // delicately arranged to nudge the compiler into producing optimized opcodes.
      assembly {
        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        toMasked := and(to, bitMaskAddress)
        // Emit the `Transfer` event.
        log4(
          0, // Start of data (0, since no data).
          0, // End of data (0, since no data).
          transferEventSig, // Signature.
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
          log4(0, 0, transferEventSig, 0, toMasked, tokenId)
        }
      }
      require(toMasked != 0, "LibERC721: Cant mint to zero address");

      ds._currentIndex = end;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
    StorageLayout storage ds = getStorage();
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = ds._currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert("LibERC721: Transfer to non ERC721Receiver");
          }
        } while (index < end);
        // Reentrancy protection.
        // solhint-disable-next-line reason-string
        if (ds._currentIndex != end) revert();
      }
    }
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  /**
   * @dev Equivalent to `_burn(tokenId, false)`.
   */
  function _burn(uint256 tokenId) internal {
    _burn(tokenId, false);
  }

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

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
  function _burn(uint256 tokenId, bool approvalCheck) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    address from = address(uint160(prevOwnershipPacked));

    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      // The nested ifs save around 20+ gas over a compound boolean condition.
      if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
        if (!isApprovedForAll(from, LibUtils.msgSender())) revert("LibERC721: Call not authorized");
    }

    LibERC721._beforeTokenTransfers(from, address(0), tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      ds._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;
      ds._packedOwnerships[tokenId] = LibERC721._packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | LibERC721._nextExtraData(from, address(0), prevOwnershipPacked)
      );

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    LibERC721._afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
      ds._burnCounter++;
    }
  }

  function isApprovedForAll(address owner, address operator) internal view returns (bool) {
    return getStorage()._operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
   */
  function _isSenderApprovedOrOwner(address approvedAddress, address owner, address msgSender) internal pure returns (bool result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      // `msgSender == owner || msgSender == approvedAddress`.
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    try IERC721Receiver(to).onERC721Received(LibUtils.msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      require(reason.length > 0, "LibERC721: Transfer to non ERC721Receiver");
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal {}

  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal {}

  function _nextInitializedFlag(uint256 quantity) internal pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(225, eq(quantity, 1))
    }
  }

  function _nextExtraData(address from, address to, uint256 prevOwnershipPacked) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> 232);
    return uint256(_extraData(from, to, extraData)) << 232;
  }

  function _extraData(address from, address to, uint24 previousExtraData) internal view returns (uint24) {}

  function _packOwnershipData(address owner, uint256 flags) internal view returns (uint256 result) {
    uint256 bitMaskAddress = (1 << 160) - 1;
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, bitMaskAddress)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(160, timestamp()), flags))
    }
  }

  function _startTokenId() internal pure returns (uint256) {
    return 1;
  }

  function nextTokenId() internal view returns (uint256) {
    return getStorage()._currentIndex;
  }

  function balanceOf(address owner) internal view returns (uint256) {
    require(owner != address(0), "LibERC721: Invalid address");
    return LibERC721.getStorage()._packedAddressData[owner] & LibERC721._BITMASK_ADDRESS_DATA_ENTRY;
  }

  function totalSupply() internal view returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId()` times.
    unchecked {
      return getStorage()._currentIndex - getStorage()._burnCounter - _startTokenId();
    }
  }

  /**
   * Returns the packed ownership data of `tokenId`.
   */
  function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256 packed) {
    StorageLayout storage ds = LibERC721.getStorage();
    if (LibERC721._startTokenId() <= tokenId) {
      packed = ds._packedOwnerships[tokenId];
      if (packed & _BITMASK_BURNED == 0) {
        if (packed == 0) {
          if (tokenId >= ds._currentIndex) revert("LibERC721: Owner query for non existing token");
          for (;;) {
            unchecked {
              packed = ds._packedOwnerships[--tokenId];
            }
            if (packed == 0) continue;
            return packed;
          }
        }
        return packed;
      }
    }
    revert("LibERC721: Owner query for non existing token");
  }

  function _getApprovedSlotAndAddress(uint256 tokenId) internal view returns (uint256 approvedAddressSlot, address approvedAddress) {
    TokenApprovalRef storage tokenApproval = getStorage()._tokenApprovals[tokenId];
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//solhint-disable no-inline-assembly

struct SaleConfig {
  uint16 id;
  bytes32 merkleRoot;
  bool active;
  uint256 price;
  uint16 maxPerTx;
  uint16 maxPerWallet;
  uint16 maxSupply;
  uint16 supply;
}

struct SaleStorage {
  uint16 saleCount;
  mapping(uint16 => SaleConfig) sales;
  mapping(address => mapping(uint16 => uint256)) addressSaleMints;
  bool allowContractsMint;
}

struct MintParams {
  uint16 saleId;
  uint16 quantity;
  bytes32[] proof;
  uint16[] seeds;
}

library LibSaleManager {
  bytes32 internal constant SALES_STORAGE_SLOT = keccak256("sales.manager.storage.library");

  function getStorage() internal pure returns (SaleStorage storage strg) {
    bytes32 slot = SALES_STORAGE_SLOT;
    assembly {
      strg.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;
//solhint-disable no-inline-assembly, not-rely-on-time

import { LibUtils } from "./LibUtils.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

struct Trait {
  string name;
  string dataURL;
  uint16 weight;
}

struct Layer {
  string name;
  uint16 traitCount;
  mapping(uint16 => Trait) traits;
}

struct LayerData {
  uint8 layerCount;
  mapping(uint8 => Layer) layers;
  mapping(uint8 => uint16) totalWeights;
  mapping(bytes32 => bool) dnaExist;
}

struct LayerSetup {
  string layerName;
  uint8 layerId;
}

struct TraitSetup {
  uint8 layerId;
  string name;
  string dataURL;
  uint16 weight;
}

struct TraitExternal {
  string layerName;
  string traitName;
  uint16 traitId;
}

struct TokenMetadataExternal {
  string name;
  TraitExternal[] attributes;
}

struct TokenMetadata {
  string name;
  uint16[] attributes;
}

struct TokenDataLayout {
  mapping(uint16 => TokenMetadata) tokens;
  mapping(uint16 => bool) tokenExist;
}

library LibTraitManager {
  bytes32 internal constant LAYER_DATA_SLOT = keccak256("trait.manager.layer.data");
  bytes32 internal constant TOKEN_DATA_SLOT = keccak256("trait.manager.token.metadata");

  /* prettier-ignore */
  string internal constant SVGTAG_HEADER = "<svg id=\"token\" width=\"100%\" height=\"100%\" version=\"1.1\" viewBox=\"0 0 64 64\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">";
  /* prettier-ignore */
  string internal constant SVGTAG_FOOTER = "<style>#token{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";
  string internal constant TOKEN_NAME_PREFIX = "My Fancy Collection #";

  function getLayerStorage() internal pure returns (LayerData storage strg) {
    bytes32 slot = LAYER_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function getTokenStorage() internal pure returns (TokenDataLayout storage strg) {
    bytes32 slot = TOKEN_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function enforceTokenExistence(uint16 tokenId) internal view {
    require(getTokenStorage().tokenExist[tokenId], "TraitManager: Token doesnt exist");
  }

  function createToken(uint16 tokenId, uint16[] calldata seeds) internal {
    TokenDataLayout storage tokenData = getTokenStorage();

    unchecked {
      tokenData.tokens[tokenId] = TokenMetadata({
        name: string(abi.encodePacked(TOKEN_NAME_PREFIX, LibUtils.numberToString(tokenId))),
        attributes: generateMetadata(tokenId, seeds)
      });
      tokenData.tokenExist[tokenId] = true;
    }
  }

  function createMultiple(uint16 startTokenId, uint16 amount, uint16[] calldata seeds) internal {
    unchecked {
      for (uint16 index = startTokenId; index < amount + startTokenId; index++) {
        createToken(index, seeds);
      }
    }
  }

  function generateMetadata(uint tokenId, uint16[] calldata seeds) internal returns (uint16[] memory) {
    LayerData storage layerStorage = getLayerStorage();

    unchecked {
      uint16 iteration = 1;
      uint16[] memory metadata = new uint16[](layerStorage.layerCount);

      for (uint8 index = 0; index < layerStorage.layerCount; index++) {
        metadata[index] = selectRandomTrait(layerStorage, index, tokenId, seeds[index], iteration, true);
      }

      bytes32 dnaHash = generateDNA(metadata);
      if (layerStorage.dnaExist[dnaHash]) {
        uint8 indexToChange = 0;
        bool foundUniqueDnaHash = false;
        while (!foundUniqueDnaHash) {
          iteration++;
          metadata[indexToChange] = selectRandomTrait(layerStorage, indexToChange, tokenId, seeds[indexToChange], iteration, true);

          dnaHash = generateDNA(metadata);
          if (!layerStorage.dnaExist[dnaHash]) {
            foundUniqueDnaHash = true;
            layerStorage.dnaExist[dnaHash] = true;
            break;
          }

          indexToChange = (indexToChange + 1) % layerStorage.layerCount;
        }
      }

      return metadata;
    }
  }

  function selectRandomTrait(
    LayerData storage layerStorage,
    uint8 layer,
    uint tokenId,
    uint seed,
    uint i,
    bool required
  ) internal view returns (uint16) {
    uint16 index;
    uint randomValIteration = 1;
    uint layerWeight = layerStorage.totalWeights[layer];

    /* solhint-disable */
    uint256 randomValue = randomize(tokenId, seed, i, layerWeight);

    if (required && randomValue == 0) {
      do {
        randomValIteration++;
        randomValue = randomize(tokenId * randomValIteration, seed * randomValIteration, i, layerWeight);
      } while (randomValue == 0);
    }
    /* solhint-enable */

    while (randomValue >= layerStorage.layers[layer].traits[index].weight) {
      randomValue -= layerStorage.layers[layer].traits[index].weight;
      index++;
    }

    return index;
  }

  function getTraitName(uint8 layerId, uint16 traitId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].traits[traitId].name;
  }

  function getLayerName(uint8 layerId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].name;
  }

  function getTraitDataURL(uint8 layerId, uint16 traitId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].traits[traitId].dataURL;
  }

  function getTokenMetadata(uint16 tokenId) internal view returns (TokenMetadataExternal memory) {
    enforceTokenExistence(tokenId);
    TokenMetadata memory token = getTokenStorage().tokens[tokenId];

    TokenMetadataExternal memory metadata;
    metadata.name = token.name;
    metadata.attributes = new TraitExternal[](token.attributes.length);

    for (uint8 index = 0; index < token.attributes.length; index++) {
      metadata.attributes[index] = TraitExternal({
        layerName: getLayerName(index),
        traitName: getTraitName(index, token.attributes[index]),
        traitId: token.attributes[index]
      });
    }

    return metadata;
  }

  function getTokenURI(uint16 tokenId) internal view returns (string memory) {
    enforceTokenExistence(tokenId);

    TokenMetadataExternal memory metadata = getTokenMetadata(tokenId);
    string memory svgData = generateSVG(metadata.attributes);

    /* prettier-ignore */
    return string(abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(bytes(string(abi.encodePacked(
        "{ \"name\": \"", metadata.name, "\", ",
          "\"attributes\": [",
            buildAttributesString(metadata.attributes),
          "], ",
          "\"image_data\": \"",
            svgData,
          "\"",
        " }"
      ))))
    ));
  }

  function buildAttributesString(TraitExternal[] memory attributes) internal pure returns (string memory) {
    string memory attributesString;
    /* prettier-ignore */
    for (uint8 i = 0; i < attributes.length; i++) {
      attributesString = string(
        abi.encodePacked(attributesString, "{ \"trait_type\": \"", attributes[i].layerName, "\", \"value\": \"", attributes[i].traitName, "\" }")
      );
      
      if (i < attributes.length - 1) {
        attributesString = string(abi.encodePacked(attributesString, ", "));
      }
    }
    return attributesString;
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                        SVG FUNCTIONS
  //
  ////////////////////////////////////////////////////////////////////

  function generateSVG(TraitExternal[] memory attributes) internal view returns (string memory) {
    string memory svg = SVGTAG_HEADER;

    for (uint8 layerId = 0; layerId < attributes.length; layerId++) {
      svg = string(abi.encodePacked(svg, wrapDataURL(getTraitDataURL(layerId, attributes[layerId].traitId))));
    }

    svg = string(abi.encodePacked(svg, SVGTAG_FOOTER));

    return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
  }

  /* prettier-ignore */
  function wrapDataURL(string memory dataURL) internal pure returns (string memory) {
    return string(abi.encodePacked("<image x=\"0\" y=\"0\" width=\"64\" height=\"64\" image-rendering=\"pixelated\" preserveAspectRatio=\"xMidYMid\" xlink:href=\"data:image/svg+xml;base64,", dataURL, "\"/>"));
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                          UTILS
  //
  ////////////////////////////////////////////////////////////////////

  function generateDNA(uint16[] memory attributes) internal pure returns (bytes32) {
    bytes memory encoded;
    uint256 length = attributes.length;

    assembly {
      let data := add(attributes, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 1)
      } {
        let attribute := mload(add(data, mul(i, 0x20)))

        encoded := add(encoded, attribute)
      }
    }

    return keccak256(encoded);
  }

  function randomize(uint tokenId, uint seed, uint iteration, uint layerWeight) internal view returns (uint256) {
    uint256 result;
    uint256 currentTimestamp = block.timestamp;

    assembly {
      let data := mload(0x40)

      mstore(data, shl(96, caller()))
      mstore(add(data, 0x20), tokenId)
      mstore(add(data, 0x40), mul(tokenId, iteration))
      mstore(add(data, 0x60), div(currentTimestamp, iteration))
      mstore(add(data, 0x80), mul(currentTimestamp, iteration))
      mstore(add(data, 0xA0), number())
      mstore(add(data, 0xC0), mul(seed, iteration))

      let hash := keccak256(data, 0xE0)
      result := mod(hash, layerWeight)
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// solhint-disable no-inline-assembly
library LibUtils {
  function msgSender() internal view returns (address sender_) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender_ = msg.sender;
    }
  }

  function numberToString(uint256 value) internal pure returns (string memory str) {
    assembly {
      let m := add(mload(0x40), 0xa0)
      mstore(0x40, m)
      str := sub(m, 0x20)
      mstore(str, 0)

      let end := str

      // prettier-ignore
      // solhint-disable-next-line no-empty-blocks
      for { let temp := value } 1 {} {
        str := sub(str, 1)
        mstore8(str, add(48, mod(temp, 10)))
        temp := div(temp, 10)
        if iszero(temp) { break }
      }

      let length := sub(end, str)
      str := sub(str, 0x20)
      mstore(str, length)
    }
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3 + i * 2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function getMax(uint256[6] memory nums) internal pure returns (uint256 maxNum) {
    maxNum = nums[0];
    for (uint256 i = 1; i < nums.length; i++) {
      if (nums[i] > maxNum) maxNum = nums[i];
    }
  }

  function compareStrings(string memory str1, string memory str2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}