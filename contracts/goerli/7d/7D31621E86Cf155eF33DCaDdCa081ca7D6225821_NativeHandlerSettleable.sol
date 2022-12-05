// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./HandlerHelpers.sol";
import "../interfaces/IDepositNative.sol";
import "../interfaces/IExecuteProposal.sol";
import "../../utils/rollup/Settleable.sol";

/// @notice This contract is intended to be used with the Bridge contract.

contract NativeHandlerSettleable is
    IDepositNative,
    IExecuteProposal,
    HandlerHelpers,
    Settleable
{
    /// @param bridgeAddress Contract address of previously deployed Bridge.
    constructor(address bridgeAddress)
        HandlerHelpers(bridgeAddress)
        Settleable(bridgeAddress)
    {}

    event NativeTokenTransfer(address indexed account, uint256 indexed amount);
    event FailedNativeTokenTransfer(
        address indexed account,
        uint256 indexed amount
    );

    /// @notice A deposit is initiatied by making a deposit in the Bridge contract.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    /// - {resourceAddress} must be allowed.
    /// - {msg.value} must be equal to {amount}.
    /// - {amount} must be greater than 0.
    /// - Recipient address in data hex string must not be zero address.
    ///
    /// @param resourceID ResourceID used to find address of token to be used for deposit.
    /// @param data Consists of {amount} padded to 32 bytes.
    /// @return an empty data.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// amount                                 uint256     bytes  0  - 32
    /// destinationRecipientAddress length     uint256     bytes  32 - 64
    /// destinationRecipientAddress            bytes       bytes  64 - END
    ///
    /// @dev Depending if the corresponding {resourceAddress} for the parsed {resourceID} is
    /// marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
    function depositNative(
        bytes32 resourceID,
        address,
        bytes calldata data
    ) external payable onlyBridge returns (bytes memory) {
        uint256 amount;
        uint256 lenDestinationRecipientAddress;
        bytes memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(
            data,
            (uint256, uint256)
        );
        destinationRecipientAddress = bytes(
            data[64:64 + lenDestinationRecipientAddress]
        );

        bytes20 recipientAddress;
        address resourceAddress = _resourceIDToTokenContractAddress[resourceID];

        // slither-disable-next-line assembly
        assembly {
            // Skip the length field (first 32 bytes) and load 32 bytes
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        require(resourceAddress == address(this), "invalid resource address");
        require(msg.value == amount, "invalid native token amount");
        require(amount > 0, "invalid amount");
        require(
            address(recipientAddress) != address(0),
            "must not be zero address"
        );

        return "";
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    /// by a relayer on the deposit's destination chain.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    /// - {resourceAddress} must be allowed.
    ///
    /// @param data Consists of {resourceID}, {amount}, {lenDestinationRecipientAddress},
    /// and {destinationRecipientAddress} all padded to 32 bytes.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// amount                                 uint256     bytes  0 - 32
    /// destinationRecipientAddress length     uint256     bytes  32 - 64
    /// destinationRecipientAddress            bytes       bytes  64 - END
    function executeProposal(bytes32 resourceID, bytes calldata data)
        external
        onlyBridge
    {
        uint256 amount;
        uint256 lenDestinationRecipientAddress;
        bytes memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(
            data,
            (uint256, uint256)
        );
        destinationRecipientAddress = bytes(
            data[64:64 + lenDestinationRecipientAddress]
        );

        bytes20 recipientAddress;
        address resourceAddress = _resourceIDToTokenContractAddress[resourceID];

        // slither-disable-next-line assembly
        assembly {
            // Skip the length field (first 32 bytes) and load 32 bytes
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }
        require(resourceAddress == address(this), "invalid resource address");
        require(
            _contractWhitelist[resourceAddress],
            "not an allowed token address"
        );
        safeTransferETH(address(recipientAddress), amount);
    }

    function safeTransferETH(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls,arbitrary-send-eth
        (bool success, ) = to.call{value: value}("");
        require(success, "native token transfer failed");
        // slither-disable-next-line reentrancy-events
        emit NativeTokenTransfer(to, value);
    }

    /// @notice Used to manually release ERC20 tokens from ERC20Safe.
    ///
    /// @notice Requirements:
    /// - {resourceAddress} must be this address.
    ///
    /// @param data Consists of {resourceAddress}, {recipient}, and {amount} all padded to 32 bytes.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// resourceAddress                        address     bytes  0  - 32
    /// recipient                              address     bytes  32 - 64
    /// amount                                 uint        bytes  64 - 96
    function withdraw(bytes memory data) external override onlyBridge {
        address resourceAddress;
        address recipient;
        uint256 amount;

        (resourceAddress, recipient, amount) = abi.decode(
            data,
            (address, address, uint256)
        );
        require(resourceAddress == address(this), "invalid resource address");

        safeTransferETH(recipient, amount);
    }

    /// @notice Requirements:
    /// - {address(this)} must be allowed.
    function _settle(KeyValuePair[] memory pairs, bytes32)
        internal
        virtual
        override
    {
        require(
            _contractWhitelist[address(this)],
            "this handler is not allowed"
        );

        for (uint256 i = 0; i < pairs.length; i++) {
            address to = abi.decode(pairs[i].key, (address));
            uint256 amount = abi.decode(pairs[i].value, (uint256));

            // To prevent potential DoS Attack, check if `to` is a deployed contract.
            // It' because a receive function of a deployed contract can revert and
            // this will cause the entire state settlement process to fail.
            uint32 size;
            // slither-disable-next-line assembly
            assembly {
                size := extcodesize(to)
            }

            // slither-disable-next-line low-level-calls,unchecked-lowlevel,arbitrary-send-eth
            (bool success, ) = to.call{value: amount}("");

            // Ether transfer must succeed only if `to` is not a deployed contract.
            if (size == 0) {
                require(success, "native token transfer failed");
            }

            // Log succeeded and failed calls.
            // It's because unchecked low-level call is used to prevent blocking operations.
            if (success) {
                // slither-disable-next-line reentrancy-events
                emit NativeTokenTransfer(to, amount);
            } else {
                // slither-disable-next-line reentrancy-events
                emit FailedNativeTokenTransfer(to, amount);
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IERCHandler.sol";

/// @notice This contract is intended to be used with the Bridge contract.

contract HandlerHelpers is IERCHandler {
    address public immutable _bridgeAddress;

    // resourceID => token contract address
    mapping(bytes32 => address) public _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping(address => bytes32) public _tokenContractAddressToResourceID;

    // token contract address => is whitelisted
    mapping(address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) public _burnList;

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    /// @param bridgeAddress Contract address of previously deployed Bridge.
    constructor(address bridgeAddress) {
        _bridgeAddress = bridgeAddress;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /// @notice Sets {_resourceIDToContractAddress} with {contractAddress},
    /// {_contractAddressToResourceID} with {resourceID},
    /// and {_contractWhitelist} to true for {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress)
        external
        override
        onlyBridge
    {
        _setResource(resourceID, contractAddress);
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external override onlyBridge {
        _setBurnable(contractAddress);
    }

    function withdraw(bytes memory data) external virtual override {}

    function _setResource(bytes32 resourceID, address contractAddress)
        internal
    {
        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;

        _contractWhitelist[contractAddress] = true;
    }

    function _setBurnable(address contractAddress) internal {
        // solhint-disable-next-line reason-string
        require(
            _contractWhitelist[contractAddress],
            "provided contract is not whitelisted"
        );
        _burnList[contractAddress] = true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDepositNative {
    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param depositor Address of account making the deposit in the Bridge contract.
    /// @param data Consists of additional data needed for a specific deposit.
    function depositNative(
        bytes32 resourceID,
        address depositor,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IExecuteProposal {
    /// @notice It is intended that proposals are executed by the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param data Consists of additional data needed for a specific deposit execution.
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RollupTypes.sol";
import "./BridgeStore.sol";

/// @notice Contract module that allows children to implement
/// state settlement mechanisms.
///
/// A settleable is a contract that has {settle} function
/// and makes state changes to destination resource.
///
/// @dev This module is supposed to be used in layer 1 (settlement layer).

abstract contract Settleable is BridgeStore {
    mapping(uint72 => uint256) private _executedBatches;

    constructor(address bridgeAddress) {
        setBridge(bridgeAddress);
    }

    /// @notice Returns the number of successfully executed batches.
    function executedBatches(uint8 originDomainID, uint64 nonce)
        external
        view
        returns (uint256)
    {
        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        return _executedBatches[nonceAndID];
    }

    /// @notice Settles state changes.
    ///
    /// @notice Requirements:
    /// - {_settleable} must be true.
    /// - It must be called only by the bridge.
    /// - Batch index must be valid.
    /// - Merkle proof must be verified.
    function settle(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes32 rootHash,
        bytes calldata data
    ) external {
        require(msg.sender == getBridge(), "Settleable: not from bridge");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);

        (uint64 batchIndex, KeyValuePair[] memory pairs) = abi.decode(
            data,
            (uint64, KeyValuePair[])
        );

        require(
            _executedBatches[nonceAndID] == batchIndex,
            "Settleable: invalid batch index"
        );
        require(
            MerkleProof.verifyCalldata(proof, rootHash, keccak256(data)),
            "Settleable: failed to verify"
        );
        _executedBatches[nonceAndID]++;

        _settle(pairs, resourceID);
    }

    /// @dev It is implemented in the following:
    /// - ERC20Settleable
    /// - ERC721Settleable
    /// - ERC20HandlerSettleable
    /// - NativeHandlerSettleable
    function _settle(KeyValuePair[] memory, bytes32) internal virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IERCHandler {
    /// @notice gets token contract address.
    /// @param resourceID resource ID that is mapped to the contract address.
    /// @return tokenContractAddress contract address that is mapped to the resource ID.
    function _resourceIDToTokenContractAddress(bytes32 resourceID)
        external
        view
        returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external;

    /// @notice Withdraw funds from ERC safes.
    /// @param data ABI-encoded withdrawal params relevant to the handler.
    function withdraw(bytes memory data) external;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

struct StateContext {
    bool _writable;
    bytes32 _hash; // writable
    uint256 _startBlock; // writable
    // readable
    uint8 _epoch;
}

struct KeyValuePair {
    bytes key;
    bytes value;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BridgeStore is Ownable {
    address private _bridge;

    event SetBridge(address indexed oldBridge, address indexed newBridge);

    /// @notice Sets bridge address.
    ///
    /// @notice Emits a {SetBridge} event.
    function setBridge(address newBridge) public onlyOwner {
        emit SetBridge(_bridge, newBridge);
        // slither-disable-next-line missing-zero-check
        _bridge = newBridge;
    }

    function getBridge() public view returns (address) {
        return _bridge;
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