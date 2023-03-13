// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./NodeOperatorRegistry.sol";

interface IDepositContractView {
    function get_deposit_root() external view returns (bytes32 rootHash);
}

contract SafeStaking is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event MaxDepositAmountUpdated(uint256 newMaxDepositAmount);
    event MinDepositTimeIntervalUpdated(uint256 newMinDepositTimeInterval);
    event SafeguardAndQuorumUpdated(address[] newSafeguards, uint256 newQuorum);
    event Paused(address safeguard);
    event Unpaused();

    bytes32 private immutable DEPOSIT_MESSAGE_PREFIX;
    bytes32 private immutable KEY_VERIFY_MESSAGE_PREFIX;
    bytes32 private immutable PAUSE_MESSAGE_PREFIX;

    IEthStakingStrategy public immutable strategy;
    IDepositContractView public immutable depositContract;
    NodeOperatorRegistry public immutable registry;

    uint256 public maxDepositAmount;
    uint256 public minDepositTimeInterval;

    EnumerableSet.AddressSet private _safeguards;
    uint256 public quorum;

    bool public paused;
    uint256 public lastDepositTimestamp;

    constructor(
        address strategy_,
        uint256 maxDepositAmount_,
        uint256 minDepositTimeInterval_
    ) public {
        strategy = IEthStakingStrategy(strategy_);
        depositContract = IDepositContractView(IEthStakingStrategy(strategy_).depositContract());
        registry = NodeOperatorRegistry(IEthStakingStrategy(strategy_).registry());
        uint256 chainID = _getChainID();
        DEPOSIT_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.DEPOSIT_MESSAGE"), chainID)
        );
        KEY_VERIFY_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.KEY_VERIFY_MESSAGE"), chainID)
        );
        PAUSE_MESSAGE_PREFIX = keccak256(
            abi.encodePacked(keccak256("chess.SafeStaking.PAUSE_MESSAGE"), chainID)
        );

        _updateMaxDepositAmount(maxDepositAmount_);
        _updateMinDepositTimeInterval(minDepositTimeInterval_);
    }

    function _getChainID() private pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getSafeguards() external view returns (address[] memory guards) {
        uint256 length = _safeguards.length();
        guards = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            guards[i] = _safeguards.at(i);
        }
    }

    function isSafeguard(address addr) public view returns (bool) {
        return _safeguards.contains(addr);
    }

    function updateMaxDepositAmount(uint256 newMaxDepositAmount) external onlyOwner {
        _updateMaxDepositAmount(newMaxDepositAmount);
    }

    function updateMinDepositTimeInterval(uint256 newMinDepositTimeInterval) external onlyOwner {
        _updateMinDepositTimeInterval(newMinDepositTimeInterval);
    }

    function updateSafeguardAndQuorum(address[] calldata newSafeguards, uint256 newQuorum)
        external
        onlyOwner
    {
        // Deletion in reverse order
        uint256 length = _safeguards.length();
        for (uint256 i = 0; i < length; i++) {
            _safeguards.remove(_safeguards.at(length - i - 1));
        }

        for (uint256 i = 0; i < newSafeguards.length; i++) {
            _safeguards.add(newSafeguards[i]);
        }

        require(newQuorum > 0, "Invalid quorum");
        quorum = newQuorum;

        emit SafeguardAndQuorumUpdated(newSafeguards, newQuorum);
    }

    function _updateMaxDepositAmount(uint256 newMaxDepositAmount) private {
        maxDepositAmount = newMaxDepositAmount;
        emit MaxDepositAmountUpdated(newMaxDepositAmount);
    }

    function _updateMinDepositTimeInterval(uint256 newMinDepositTimeInterval) private {
        require(newMinDepositTimeInterval > 0, "Invalid value");
        minDepositTimeInterval = newMinDepositTimeInterval;
        emit MinDepositTimeIntervalUpdated(newMinDepositTimeInterval);
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    /// @dev Pauses the contract given that both conditions:
    ///         1. The function is called by the safeguard OR the signature is valid
    ///         2. block.timestamp <= timestamp
    ///
    ///      The signature, if present, must be produced for keccak256 hash of the following
    ///      message (each component taking 32 bytes):
    ///
    ///      | PAUSE_MESSAGE_PREFIX | timestamp |
    function pause(uint256 timestamp, bytes memory signature) external whenNotPaused {
        address safeguardAddr = msg.sender;
        if (!isSafeguard(safeguardAddr)) {
            bytes32 msgHash = keccak256(abi.encodePacked(PAUSE_MESSAGE_PREFIX, timestamp));
            safeguardAddr = ECDSA.recover(msgHash, signature);
            require(isSafeguard(safeguardAddr), "Invalid signature");
        }

        require(block.timestamp <= timestamp, "Pause intent expired");

        paused = true;
        emit Paused(safeguardAddr);
    }

    function unpause() external onlyOwner {
        if (paused) {
            paused = false;
            emit Unpaused();
        }
    }

    /// @dev whether `safeDeposit` can be called, given that
    ///         1. The contract is not paused
    ///         2. The contract has been initalized
    ///         3. the last deposit was made at least `minDepositTimeInterval` seconds ago
    /// @return canDeposit whether `safeDeposit` can be called
    function canDeposit() external view returns (bool) {
        return
            !paused &&
            quorum > 0 &&
            block.timestamp - lastDepositTimestamp >= minDepositTimeInterval;
    }

    /// @dev Calls EthStakingStrategy.deposit(amount).
    ///      Reverts if any of the following is true:
    ///         1. depositRoot != depositContract.get_deposit_root()
    ///         2. registryVersion != registry.version()
    ///         3. The number of safeguard signatures is less than safeguard quorum
    ///         4. An invalid or non-safeguard signature received
    ///         5. depositAmount > maxDepositAmount
    ///         6. block.timestamp - getlastDepositTimestamp() < minDepositTimeInterval
    ///         7. blockHash != blockhash(blockNumber)
    ///
    ///      Signatures must be sorted in ascending order by address of the safeguards. Each signature must
    ///      be produced for keccak256 hash of the following message (each component taking 32 bytes):
    ///
    ///      | DEPOSIT_MESSAGE_PREFIX | depositRoot | registryVersion | blockNumber | blockHash | depositAmount
    function safeDeposit(
        bytes32 depositRoot,
        uint256 registryVersion,
        uint256 blockNumber,
        bytes32 blockHash,
        uint256 depositAmount,
        bytes memory signatures
    ) external whenNotPaused {
        require(depositRoot == depositContract.get_deposit_root(), "Deposit root changed");
        require(registryVersion == registry.registryVersion(), "Registry version changed");
        require(depositAmount <= maxDepositAmount, "Deposit amount exceeds max one-time deposit");
        require(
            block.timestamp - lastDepositTimestamp >= minDepositTimeInterval,
            "Too frequent deposits"
        );
        require(
            blockHash != bytes32(0) && blockhash(blockNumber) == blockHash,
            "Unexpected blockhash"
        );

        bytes32 msgHash =
            keccak256(
                abi.encodePacked(
                    DEPOSIT_MESSAGE_PREFIX,
                    depositRoot,
                    registryVersion,
                    blockNumber,
                    blockHash,
                    depositAmount
                )
            );
        _verifySignatures(msgHash, signatures);

        strategy.deposit(depositAmount);
        lastDepositTimestamp = block.timestamp;
    }

    function safeVerifyKeys(
        uint256 id,
        uint64 newVerifiedCount,
        uint256 registryVersion,
        bytes memory signatures
    ) external whenNotPaused {
        bytes32 msgHash =
            keccak256(
                abi.encodePacked(KEY_VERIFY_MESSAGE_PREFIX, id, newVerifiedCount, registryVersion)
            );
        _verifySignatures(msgHash, signatures);

        registry.updateVerifiedCount(id, newVerifiedCount, registryVersion);
    }

    function _verifySignatures(bytes32 msgHash, bytes memory signatures) private view {
        uint256 length = signatures.length / 65;
        require(
            quorum > 0 && length >= quorum && signatures.length % 65 == 0,
            "No safeguard quorum"
        );
        address prevSignerAddr = address(0);
        for (uint256 i = 0; i < length; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signatures, i);
            address signerAddr = ECDSA.recover(msgHash, v, r, s);
            require(isSafeguard(signerAddr), "Invalid signature");
            require(signerAddr > prevSignerAddr, "Signatures not sorted");
            prevSignerAddr = signerAddr;
        }
    }

    /// @dev divides compact bytes signature {bytes32 r}{bytes32 s}{uint8 v} into `uint8 v, bytes32 r, bytes32 s`.
    ///      Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function _splitSignature(bytes memory signatures, uint256 pos)
        private
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            let signaturePos := add(signatures, mul(0x41, pos))
            r := mload(add(signaturePos, 0x20))
            s := mload(add(signaturePos, 0x40))
            v := byte(0, mload(add(signaturePos, 0x60)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 */
library EnumerableSet {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IWithdrawalManager.sol";
import "./WithdrawalManagerFactory.sol";

interface IEthStakingStrategy {
    function safeStaking() external view returns (address);

    function registry() external view returns (address);

    function depositContract() external view returns (address);

    function deposit(uint256 amount) external;
}

contract NodeOperatorRegistry is Ownable {
    event OperatorAdded(uint256 indexed id, string name, address operatorOwner);
    event OperatorOwnerUpdated(uint256 indexed id, address newOperatorOwner);
    event RewardAddressUpdated(uint256 indexed id, address newRewardAddress);
    event VerifiedCountUpdated(uint256 indexed id, uint256 newVerifiedCount);
    event DepositLimitUpdated(uint256 indexed id, uint256 newDepositLimit);
    event KeyAdded(uint256 indexed id, bytes pubkey, uint256 index);
    event KeyUsed(uint256 indexed id, uint256 count);
    event KeyTruncated(uint256 indexed id, uint256 newTotalCount);
    event StrategyUpdated(address newStrategy);

    /// @notice Statistics of validator pubkeys from a node operator.
    /// @param totalCount Total number of validator pubkeys uploaded to this contract
    /// @param usedCount Number of validator pubkeys that are already used
    /// @param verifiedCount Number of validator pubkeys that are verified by the contract owner
    /// @param depositLimit Maximum number of usable validator pubkeys, set by the node operator
    struct KeyStat {
        uint64 totalCount;
        uint64 usedCount;
        uint64 verifiedCount;
        uint64 depositLimit;
    }

    /// @notice Node operator parameters and internal state
    /// @param operatorOwner Admin address of the node operator
    /// @param name Human-readable name
    /// @param withdrawalAddress Address receiving withdrawals and execution layer rewards
    /// @param rewardAddress Address receiving performance rewards
    struct Operator {
        address operatorOwner;
        string name;
        address rewardAddress;
        address withdrawalAddress;
        KeyStat keyStat;
    }

    struct Key {
        bytes32 pubkey0;
        bytes32 pubkey1; // Only the higher 16 bytes of the second slot are used
        bytes32 signature0;
        bytes32 signature1;
        bytes32 signature2;
    }

    uint256 private constant PUBKEY_LENGTH = 48;
    uint256 private constant SIGNATURE_LENGTH = 96;

    WithdrawalManagerFactory public immutable factory;

    address public strategy;

    /// @notice Number of node operators.
    uint256 public operatorCount;

    /// @dev Mapping of node operator ID => node operator.
    mapping(uint256 => Operator) private _operators;

    /// @dev Mapping of node operator ID => index => validator pubkey and deposit signature.
    mapping(uint256 => mapping(uint256 => Key)) private _keys;

    uint256 public registryVersion;

    constructor(address strategy_, address withdrawalManagerFactory_) public {
        _updateStrategy(strategy_);
        factory = WithdrawalManagerFactory(withdrawalManagerFactory_);
    }

    function initialize(address oldRegistry) external onlyOwner {
        require(operatorCount == 0);

        operatorCount = NodeOperatorRegistry(oldRegistry).operatorCount();
        for (uint256 i = 0; i < operatorCount; i++) {
            Operator memory operator = NodeOperatorRegistry(oldRegistry).getOperator(i);
            operator.operatorOwner = msg.sender;
            uint64 usedCount = operator.keyStat.usedCount;
            operator.keyStat.totalCount = usedCount;
            operator.keyStat.verifiedCount = usedCount;
            _operators[i] = operator;
            emit OperatorAdded(i, operator.name, msg.sender);
            if (operator.rewardAddress != msg.sender) {
                emit RewardAddressUpdated(i, operator.rewardAddress);
            }
            emit DepositLimitUpdated(i, operator.keyStat.depositLimit);

            Key[] memory keys = NodeOperatorRegistry(oldRegistry).getKeys(i, 0, usedCount);
            for (uint256 j = 0; j < usedCount; j++) {
                bytes32 pk0 = keys[j].pubkey0;
                bytes32 pk1 = keys[j].pubkey1;
                _keys[i][j].pubkey0 = pk0;
                _keys[i][j].pubkey1 = pk1;
                emit KeyAdded(i, abi.encodePacked(pk0, bytes16(pk1)), j);
            }
            emit VerifiedCountUpdated(i, usedCount);
            emit KeyUsed(i, usedCount);
        }
    }

    function getOperator(uint256 id) external view returns (Operator memory) {
        return _operators[id];
    }

    function getOperators() external view returns (Operator[] memory operators) {
        uint256 count = operatorCount;
        operators = new Operator[](count);
        for (uint256 i = 0; i < count; i++) {
            operators[i] = _operators[i];
        }
    }

    function getRewardAddress(uint256 id) external view returns (address) {
        return _operators[id].rewardAddress;
    }

    function getRewardAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].rewardAddress;
        }
    }

    function getWithdrawalAddress(uint256 id) external view returns (address) {
        return _operators[id].withdrawalAddress;
    }

    function getWithdrawalAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].withdrawalAddress;
        }
    }

    function getWithdrawalCredential(uint256 id) external view returns (bytes32) {
        return IWithdrawalManager(_operators[id].withdrawalAddress).getWithdrawalCredential();
    }

    function getKeyStat(uint256 id) external view returns (KeyStat memory) {
        return _operators[id].keyStat;
    }

    function getKeyStats() external view returns (KeyStat[] memory keyStats) {
        uint256 count = operatorCount;
        keyStats = new KeyStat[](count);
        for (uint256 i = 0; i < count; i++) {
            keyStats[i] = _operators[i].keyStat;
        }
    }

    function getKey(uint256 id, uint256 index) external view returns (Key memory) {
        return _keys[id][index];
    }

    function getKeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (Key[] memory keys) {
        keys = new Key[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            keys[i] = operatorKeys[start + i];
        }
    }

    function getPubkeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory pubkeys) {
        pubkeys = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            pubkeys[i] = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        }
    }

    function getSignatures(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory signatures) {
        signatures = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            signatures[i] = abi.encode(key.signature0, key.signature1, key.signature2);
        }
    }

    function addKeys(
        uint256 id,
        bytes calldata pubkeys,
        bytes calldata signatures
    ) external onlyOperatorOwner(id) {
        uint256 count = pubkeys.length / PUBKEY_LENGTH;
        require(
            pubkeys.length == count * PUBKEY_LENGTH &&
                signatures.length == count * SIGNATURE_LENGTH,
            "Invalid param length"
        );
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        for (uint256 i = 0; i < count; ++i) {
            Key memory key;
            key.pubkey0 = abi.decode(pubkeys[i * PUBKEY_LENGTH:i * PUBKEY_LENGTH + 32], (bytes32));
            key.pubkey1 = abi.decode(
                pubkeys[i * PUBKEY_LENGTH + 16:i * PUBKEY_LENGTH + 48],
                (bytes32)
            );
            key.pubkey1 = bytes32(uint256(key.pubkey1) << 128);
            (key.signature0, key.signature1, key.signature2) = abi.decode(
                signatures[i * SIGNATURE_LENGTH:(i + 1) * SIGNATURE_LENGTH],
                (bytes32, bytes32, bytes32)
            );
            require(
                key.pubkey0 | key.pubkey1 != 0 &&
                    key.signature0 | key.signature1 | key.signature2 != 0,
                "Empty pubkey or signature"
            );
            operatorKeys[stat.totalCount + i] = key;
            emit KeyAdded(
                id,
                abi.encodePacked(key.pubkey0, bytes16(key.pubkey1)),
                stat.totalCount + i
            );
        }
        stat.totalCount += uint64(count);
        operator.keyStat = stat;
        registryVersion++;
    }

    function truncateUnusedKeys(uint256 id) external onlyOperatorOwner(id) {
        _truncateUnusedKeys(id);
    }

    function updateRewardAddress(uint256 id, address newRewardAddress)
        external
        onlyOperatorOwner(id)
    {
        _operators[id].rewardAddress = newRewardAddress;
        emit RewardAddressUpdated(id, newRewardAddress);
    }

    function updateDepositLimit(uint256 id, uint64 newDepositLimit) external onlyOperatorOwner(id) {
        _operators[id].keyStat.depositLimit = newDepositLimit;
        registryVersion++;
        emit DepositLimitUpdated(id, newDepositLimit);
    }

    function useKeys(uint256 id, uint256 count)
        external
        onlyStrategy
        returns (Key[] memory keys, bytes32 withdrawalCredential)
    {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        uint256 usedCount = stat.usedCount;
        uint256 newUsedCount = usedCount + count;
        require(
            newUsedCount <= stat.totalCount &&
                newUsedCount <= stat.depositLimit &&
                newUsedCount <= stat.verifiedCount,
            "No enough pubkeys"
        );
        keys = new Key[](count);
        for (uint256 i = 0; i < count; i++) {
            Key storage k = operatorKeys[usedCount + i];
            keys[i] = k;
            // Clear storage for gas refund
            k.signature0 = 0;
            k.signature1 = 0;
            k.signature2 = 0;
        }
        stat.usedCount = uint64(newUsedCount);
        operator.keyStat = stat;
        withdrawalCredential = IWithdrawalManager(operator.withdrawalAddress)
            .getWithdrawalCredential();
        registryVersion++;
        emit KeyUsed(id, count);
    }

    function addOperator(string calldata name, address operatorOwner)
        external
        onlyOwner
        returns (uint256 id, address withdrawalAddress)
    {
        id = operatorCount++;
        withdrawalAddress = factory.deployContract(id);
        Operator storage operator = _operators[id];
        operator.operatorOwner = operatorOwner;
        operator.name = name;
        operator.withdrawalAddress = withdrawalAddress;
        operator.rewardAddress = operatorOwner;
        emit OperatorAdded(id, name, operatorOwner);
    }

    function updateOperatorOwner(uint256 id, address newOperatorOwner) external onlyOwner {
        require(id < operatorCount, "Invalid operator ID");
        _operators[id].operatorOwner = newOperatorOwner;
        emit OperatorOwnerUpdated(id, newOperatorOwner);
    }

    function updateVerifiedCount(
        uint256 id,
        uint64 newVerifiedCount,
        uint256 offchainregistryVersion
    ) external {
        require(msg.sender == IEthStakingStrategy(strategy).safeStaking(), "Only safe staking");
        require(registryVersion == offchainregistryVersion, "Registry version changed");

        _operators[id].keyStat.verifiedCount = newVerifiedCount;
        registryVersion++;
        emit VerifiedCountUpdated(id, newVerifiedCount);
    }

    function truncateAllUnusedKeys() external onlyOwner {
        uint256 count = operatorCount;
        for (uint256 i = 0; i < count; i++) {
            _truncateUnusedKeys(i);
        }
    }

    function _truncateUnusedKeys(uint256 id) private {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        stat.totalCount = stat.usedCount;
        stat.verifiedCount = stat.usedCount;
        operator.keyStat = stat;
        emit KeyTruncated(id, stat.totalCount);
    }

    function updateStrategy(address newStrategy) external onlyOwner {
        _updateStrategy(newStrategy);
    }

    function _updateStrategy(address newStrategy) private {
        strategy = newStrategy;
        emit StrategyUpdated(newStrategy);
    }

    modifier onlyOperatorOwner(uint256 id) {
        require(msg.sender == _operators[id].operatorOwner, "Only operator owner");
        _;
    }

    modifier onlyStrategy() {
        require(msg.sender == strategy, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IWithdrawalManager {
    function getWithdrawalCredential() external view returns (bytes32);

    function transferToStrategy(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./WithdrawalManagerProxy.sol";

contract WithdrawalManagerFactory is Ownable {
    event ImplementationUpdated(address indexed newImplementation);

    address public implementation;

    constructor(address implementation_) public {
        _updateImplementation(implementation_);
    }

    function deployContract(uint256 id) external returns (address) {
        WithdrawalManagerProxy proxy = new WithdrawalManagerProxy(this, id);
        return address(proxy);
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        _updateImplementation(newImplementation);
    }

    function _updateImplementation(address newImplementation) private {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "./WithdrawalManagerFactory.sol";

// An individual withdraw maanger for a node operator

contract WithdrawalManagerProxy is Proxy {
    using Address for address;

    WithdrawalManagerFactory internal immutable withdrawalManagerFactory;

    constructor(WithdrawalManagerFactory withdrawalManagerFactory_, uint256 operatorID_) public {
        // Initialize withdrawalManagerFactory
        require(address(withdrawalManagerFactory_) != address(0x0), "Invalid factory address");
        withdrawalManagerFactory = withdrawalManagerFactory_;
        // Check for contract existence
        address implAddress = withdrawalManagerFactory_.implementation();
        require(implAddress.isContract(), "Delegate contract does not exist");
        // Call Initialize on delegate
        (bool success, ) =
            implAddress.delegatecall(abi.encodeWithSignature("initialize(uint256)", operatorID_));
        if (!success) {
            revert("Failed delegatecall");
        }
    }

    function _implementation() internal view override returns (address) {
        return withdrawalManagerFactory.implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}