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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

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

interface IContractMetadata {
    /// @notice Contract name returns the pretty contract name
    function contractName() external returns (string memory);

    /// @notice Contract URI returns the uri for more information about the given contract
    function contractURI() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Creator Commands used by minter modules passed back to the main modules
interface ICreatorCommands {
    /// @notice This enum is used to define supported creator action types.
    /// This can change in the future
    enum CreatorActions {
        // No operation - also the default for mintings that may not return a command
        NO_OP,
        // Send ether
        SEND_ETH,
        // Mint operation
        MINT
    }

    /// @notice This command is for
    struct Command {
        // Method for operation
        CreatorActions method;
        // Arguments used for this operation
        bytes args;
    }

    /// @notice This command set is returned from the minter back to the user
    struct CommandSet {
        Command[] commands;
        uint256 at;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {ICreatorCommands} from "./ICreatorCommands.sol";

/// @notice Minter standard interface
/// @dev Minters need to confirm to the ERC165 selector of type(IMinter1155).interfaceId
interface IMinter1155 is IERC165Upgradeable {
    function requestMint(
        address sender,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVersionedContract {
    function contractVersion() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";

/// @title SaleCommandHelper
/// @notice Helper library for creating commands for the sale contract
/// @author @iainnash / @tbtstl
library SaleCommandHelper {
    /// @notice Sets the size of commands and initializes command array. Empty entries are skipped by the resolver.
    /// @dev Beware: this removes all previous command entries from memory
    /// @param commandSet command set struct storage.
    /// @param size size to set for the new struct
    function setSize(ICreatorCommands.CommandSet memory commandSet, uint256 size) internal pure {
        commandSet.commands = new ICreatorCommands.Command[](size);
    }

    /// @notice Creates a command to mint a token
    /// @param commandSet The command set to add the command to
    /// @param to The address to mint to
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    function mint(ICreatorCommands.CommandSet memory commandSet, address to, uint256 tokenId, uint256 quantity) internal pure {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({
                method: ICreatorCommands.CreatorActions.MINT,
                args: abi.encode(to, tokenId, quantity)
            });
        }
    }

    /// @notice Creates a command to transfer ETH
    /// @param commandSet The command set to add the command to
    /// @param to The address to transfer to
    /// @param amount The amount of ETH to transfer
    function transfer(ICreatorCommands.CommandSet memory commandSet, address to, uint256 amount) internal pure {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({method: ICreatorCommands.CreatorActions.SEND_ETH, args: abi.encode(to, amount)});
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IContractMetadata} from "../interfaces/IContractMetadata.sol";
import {IVersionedContract} from "../interfaces/IVersionedContract.sol";
import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";
import {SaleCommandHelper} from "./SaleCommandHelper.sol";

/// @notice Sales Strategy Helper contract template on top of IMinter1155
/// @author @iainnash / @tbtstl
abstract contract SaleStrategy is IMinter1155, IVersionedContract, IContractMetadata {
    /// @notice This function resets the sales configuration for a given tokenId and contract.
    /// @dev This function is intentioned to be called directly from the affected sales contract
    function resetSale(uint256 tokenId) external virtual;

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IMinter1155).interfaceId || interfaceId == type(IERC165Upgradeable).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IMinter1155} from "../../interfaces/IMinter1155.sol";
import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";
import {TransferHelperUtils} from "../../utils/TransferHelperUtils.sol";
import {SaleStrategy} from "../SaleStrategy.sol";
import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";
import {SaleCommandHelper} from "../SaleCommandHelper.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-1155-contracts

 */

/// @title ZoraCreatorMerkleMinterStrategy
/// @notice Mints tokens based on a merkle tree, for presales for example
/// @author @iainnash / @tbtstl
contract ZoraCreatorMerkleMinterStrategy is SaleStrategy {
    using SaleCommandHelper for ICreatorCommands.CommandSet;

    /// @notice General merkle sale settings
    struct MerkleSaleSettings {
        /// @notice Unix timestamp for the sale start
        uint64 presaleStart;
        /// @notice Unix timestamp for the sale end
        uint64 presaleEnd;
        /// @notice Funds recipient (0 if no different funds recipient than the contract global)
        address fundsRecipient;
        /// @notice Merkle root for
        bytes32 merkleRoot;
    }

    /// @notice Event for sale configuration updated
    event SaleSet(address indexed mediaContract, uint256 indexed tokenId, MerkleSaleSettings merkleSaleSettings);

    /// @notice Storage for allowed merkle settings for the sales configuration
    mapping(address => mapping(uint256 => MerkleSaleSettings)) public allowedMerkles;
    // target -> tokenId -> settings

    /// @notice Storage for the number minted per address
    mapping(address => mapping(uint256 => mapping(address => uint256))) public mintedPerAddress;
    // target -> tokenId -> minter -> count

    error SaleEnded();
    error SaleHasNotStarted();
    error MintedTooManyForAddress();
    error WrongValueSent();
    error InvalidMerkleProof(address mintTo, bytes32[] merkleProof, bytes32 merkleRoot);

    /// @notice ContractURI for contract information with the strategy
    function contractURI() external pure override returns (string memory) {
        return "https://github.com/ourzora/zora-1155-contracts/";
    }

    /// @notice The name of the sale strategy
    function contractName() external pure override returns (string memory) {
        return "Merkle Tree Sale Strategy";
    }

    /// @notice The version of the sale strategy
    function contractVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    error MerkleClaimsExceeded();

    /// @notice Compiles and returns the commands needed to mint a token using this sales strategy
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param ethValueSent The amount of ETH sent with the transaction
    /// @param minterArguments The arguments passed to the minter, which should be the address to mint to, the max quantity, the price per token, and the merkle proof
    function requestMint(
        address,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands) {
        (address mintTo, uint256 maxQuantity, uint256 pricePerToken, bytes32[] memory merkleProof) = abi.decode(
            minterArguments,
            (address, uint256, uint256, bytes32[])
        );

        MerkleSaleSettings memory config = allowedMerkles[msg.sender][tokenId];

        // Check sale end
        if (block.timestamp > config.presaleEnd) {
            revert SaleEnded();
        }

        // Check sale start
        if (block.timestamp < config.presaleStart) {
            revert SaleHasNotStarted();
        }

        if (!MerkleProof.verify(merkleProof, config.merkleRoot, keccak256(abi.encode(mintTo, maxQuantity, pricePerToken)))) {
            revert InvalidMerkleProof(mintTo, merkleProof, config.merkleRoot);
        }

        if (maxQuantity > 0) {
            mintedPerAddress[msg.sender][tokenId][mintTo] += quantity;
            if (mintedPerAddress[msg.sender][tokenId][mintTo] > maxQuantity) {
                revert MintedTooManyForAddress();
            }
        }

        if (quantity * pricePerToken != ethValueSent) {
            revert WrongValueSent();
        }

        // Should transfer funds if funds recipient is set to a non-default address
        bool shouldTransferFunds = config.fundsRecipient != address(0);

        // Setup contract commands
        commands.setSize(shouldTransferFunds ? 2 : 1);

        // Mint command
        commands.mint(mintTo, tokenId, quantity);

        // If we have a non-default funds recipient for this token
        if (shouldTransferFunds) {
            commands.transfer(config.fundsRecipient, ethValueSent);
        }
    }

    /// @notice Sets the sale configuration for a token
    function setSale(uint256 tokenId, MerkleSaleSettings memory merkleSaleSettings) external {
        allowedMerkles[msg.sender][tokenId] = merkleSaleSettings;

        // Emit event for new sale
        emit SaleSet(msg.sender, tokenId, merkleSaleSettings);
    }

    /// @notice Resets the sale configuration for a token
    function resetSale(uint256 tokenId) external override {
        delete allowedMerkles[msg.sender][tokenId];

        // Emit event with empty sale
        emit SaleSet(msg.sender, tokenId, allowedMerkles[msg.sender][tokenId]);
    }

    /// @notice Gets the sale configuration for a token
    function sale(address tokenContract, uint256 tokenId) external view returns (MerkleSaleSettings memory) {
        return allowedMerkles[tokenContract][tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title TransferHelperUtils
/// @notice Helper functions for sending ETH
library TransferHelperUtils {
    /// @dev Gas limit to send funds
    uint256 internal constant FUNDS_SEND_LOW_GAS_LIMIT = 110_000;

    // @dev Gas limit to send funds – usable for splits, can use with withdraws
    uint256 internal constant FUNDS_SEND_GAS_LIMIT = 310_000;

    /// @notice Sends ETH to a recipient, making conservative estimates to not run out of gas
    /// @param recipient The address to send ETH to
    /// @param value The amount of ETH to send
    function safeSendETHLowLimit(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = recipient.call{value: value, gas: FUNDS_SEND_LOW_GAS_LIMIT}("");
    }

    /// @notice Sends ETH to a recipient, making an attempt to not run out of gas
    /// @param recipient The address to send ETH to
    /// @param value The amount of ETH to send
    function safeSendETH(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = recipient.call{value: value, gas: FUNDS_SEND_GAS_LIMIT}("");
    }
}