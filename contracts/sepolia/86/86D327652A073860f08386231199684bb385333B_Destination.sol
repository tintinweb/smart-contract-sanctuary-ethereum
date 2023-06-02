// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { SYSTEM_ROUTER } from "./libs/Constants.sol";
import { MerkleLib } from "./libs/Merkle.sol";
import { Header, Message, MessageLib, Tips } from "./libs/Message.sol";
import { StateLib } from "./libs/State.sol";
import { TypeCasts } from "./libs/TypeCasts.sol";
import { TypedMemView } from "./libs/TypedMemView.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { DomainContext } from "./context/DomainContext.sol";
import { DestinationEvents } from "./events/DestinationEvents.sol";
import { InterfaceDestination, ORIGIN_TREE_DEPTH } from "./interfaces/InterfaceDestination.sol";
import { IMessageRecipient } from "./interfaces/IMessageRecipient.sol";
import { DestinationAttestation, AttestationHub } from "./hubs/AttestationHub.sol";
import { Attestation, StatementHub } from "./hubs/StatementHub.sol";
import { SystemRegistry } from "./system/SystemRegistry.sol";

contract Destination is
    StatementHub,
    AttestationHub,
    SystemRegistry,
    DestinationEvents,
    InterfaceDestination
{
    using MessageLib for bytes;
    using TypedMemView for bytes29;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              CONSTANTS                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    bytes32 internal constant MESSAGE_STATUS_NONE = bytes32(0);

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               STORAGE                                ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice (messageHash => status)
    /// TODO: Store something else as "status"? Notary/timestamp?
    /// - Message hasn't been executed: MESSAGE_STATUS_NONE
    /// - Message has been executed: snapshot root used for proving when executed
    /// @dev Messages coming from different origins will always have a different hash
    /// as origin domain is encoded into the formatted message.
    /// Thus we can use hash as a key instead of an (origin, hash) tuple.
    mapping(bytes32 => bytes32) public messageStatus;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                      CONSTRUCTOR & INITIALIZER                       ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    constructor(uint32 _domain) DomainContext(_domain) {}

    /// @notice Initializes Origin contract:
    /// - msg.sender is set as contract owner
    function initialize() external initializer {
        // Initialize SystemContract: msg.sender is set as "owner"
        __SystemContract_initialize();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          ACCEPT STATEMENTS                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @inheritdoc InterfaceDestination
    function submitAttestation(bytes memory _attPayload, bytes memory _attSignature)
        external
        returns (bool wasAccepted)
    {
        // This will revert if payload is not an attestation, or signer is not an active Notary
        (Attestation att, uint32 domain, address notary) = _verifyAttestation(
            _attPayload,
            _attSignature
        );
        // Check that Notary is active on local domain
        require(domain == localDomain, "Wrong Notary domain");
        // This will revert if snapshot root has been previously submitted
        _acceptAttestation(att, notary);
        emit AttestationAccepted(domain, notary, _attPayload, _attSignature);
        return true;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           EXECUTE MESSAGES                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @inheritdoc InterfaceDestination
    function execute(
        bytes memory _message,
        bytes32[ORIGIN_TREE_DEPTH] calldata _originProof,
        bytes32[] calldata _snapProof,
        uint256 _stateIndex
    ) external {
        // This will revert if payload is not a formatted message payload
        Message message = _message.castToMessage();
        Header header = message.header();
        bytes32 msgLeaf = message.leaf();
        // Check proofs validity and mark message as executed
        DestinationAttestation memory destAtt = _prove(
            header,
            msgLeaf,
            _originProof,
            _snapProof,
            _stateIndex
        );
        // Store message tips
        Tips tips = message.tips();
        _storeTips(destAtt.notary, tips);
        // Get the specified recipient address
        uint32 origin = header.origin();
        address recipient = _checkForSystemRouter(header.recipient());
        // Pass the message to the recipient
        IMessageRecipient(recipient).handle(
            origin,
            header.nonce(),
            header.sender(),
            destAtt.destTimestamp,
            message.body().clone()
        );
        emit Executed(origin, msgLeaf);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            INTERNAL LOGIC                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Attempts to prove the validity of the cross-chain message.
     * First, the origin Merkle Root is reconstructed using the origin proof.
     * Then the origin state's "left leaf" is reconstructed using the origin domain.
     * After that the snapshot Merkle Root is reconstructed using the snapshot proof.
     * Finally, the optimistic period is checked for the derived snapshot root.
     * @dev Reverts if any of the checks fail.
     * @param _header       Typed memory view over message header payload
     * @param _msgLeaf      Message Leaf that was inserted in the Origin Merkle Tree
     * @param _originProof  Proof of inclusion of Message Leaf in the Origin Merkle Tree
     * @param _snapProof    Proof of inclusion of Origin State Left Leaf into Snapshot Merkle Tree
     * @param _stateIndex   Index of Origin State in the Snapshot
     * @return destAtt      Attestation data for derived snapshot root
     */
    function _prove(
        Header _header,
        bytes32 _msgLeaf,
        bytes32[ORIGIN_TREE_DEPTH] calldata _originProof,
        bytes32[] calldata _snapProof,
        uint256 _stateIndex
    ) internal returns (DestinationAttestation memory destAtt) {
        // TODO: split into a few smaller functions?
        // Check that message has not been executed before
        require(messageStatus[_msgLeaf] == MESSAGE_STATUS_NONE, "!MessageStatus.None");
        // Ensure message was meant for this domain
        require(_header.destination() == localDomain, "!destination");
        // Reconstruct Origin Merkle Root using the origin proof
        // Message index in the tree is (nonce - 1), as nonce starts from 1
        bytes32 originRoot = MerkleLib.branchRoot(_msgLeaf, _originProof, _header.nonce() - 1);
        // Reconstruct left sub-leaf of the Origin State: (merkleRoot, originDomain)
        bytes32 leftLeaf = StateLib.leftLeaf(originRoot, _header.origin());
        // Reconstruct Snapshot Merkle Root using the snapshot proof
        // Index of "leftLeaf" is twice the state position in the snapshot
        /// @dev We ask to provide state index instead of "leftLeaf" index to enforce
        /// choice of State's left leaf for root reconstruction
        bytes32 snapshotRoot = MerkleLib.branchRoot(leftLeaf, _snapProof, _stateIndex << 1);
        // Fetch the attestation data for the snapshot root
        destAtt = _rootAttestation(snapshotRoot);
        // Check if snapshot root has been submitted
        require(!destAtt.isEmpty(), "Invalid snapshot root");
        // Check that snapshot proof length matches the height of Snapshot Merkle Tree
        require(_snapProof.length == destAtt.height, "Invalid proof length");
        // Check if Notary who submitted the snapshot is still active
        require(_isActiveAgent(localDomain, destAtt.notary), "Inactive notary");
        // Check if optimistic period has passed
        require(
            block.timestamp >= _header.optimisticSeconds() + destAtt.destTimestamp,
            "!optimisticSeconds"
        );
        // Mark message as executed against the snapshot root
        messageStatus[_msgLeaf] = snapshotRoot;
    }

    function _storeTips(address _notary, Tips _tips) internal {
        // TODO: implement tips logic
        emit TipsStored(_notary, _tips.unwrap().clone());
    }

    /**
     * @notice Returns adjusted "recipient" field.
     * @dev By default, "recipient" field contains the recipient address padded to 32 bytes.
     * But if SYSTEM_ROUTER value is used for "recipient" field, recipient is Synapse Router.
     * Note: tx will revert in Origin if anyone but SystemRouter uses SYSTEM_ROUTER as recipient.
     */
    function _checkForSystemRouter(bytes32 _recipient) internal view returns (address recipient) {
        // Check if SYSTEM_ROUTER was specified as message recipient
        if (_recipient == SYSTEM_ROUTER) {
            /**
             * @dev Route message to SystemRouter.
             * Note: Only SystemRouter contract on origin chain can send a message
             * using SYSTEM_ROUTER as "recipient" field (enforced in Origin.sol).
             */
            recipient = address(systemRouter);
        } else {
            // Cast bytes32 to address otherwise
            recipient = TypeCasts.bytes32ToAddress(_recipient);
        }
    }

    function _isIgnoredAgent(uint32 _domain, address)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // Destination only keeps track of local Notaries and Guards
        return _domain != localDomain && _domain != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Here we define common constants to enable their easier reusing later.

/// @dev See Attestation.sol: (bytes32,uint8,uint32,uint40,uint40): 32+1+4+5+5
uint256 constant ATTESTATION_LENGTH = 47;

/// @dev See State.sol: (bytes32,uint32,uint32,uint40,uint40): 32+4+4+5+5
uint256 constant STATE_LENGTH = 50;

/// @dev Maximum amount of states in a single snapshot
uint256 constant SNAPSHOT_MAX_STATES = 32;

/// @dev Root for an empty Origin Merkle Tree.
bytes32 constant EMPTY_ROOT = hex"27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757";

/// @dev Depth of the Origin Merkle Tree
uint256 constant ORIGIN_TREE_DEPTH = 32;

/// @dev Maximum bytes per message = 2 KiB (somewhat arbitrarily set to begin)
uint256 constant MAX_MESSAGE_BODY_BYTES = 2 * 2**10;

/**
 * @dev Custom address used for sending and receiving system messages.
 *  - Origin will dispatch messages from SystemRouter as if they were "sent by this sender".
 *  - Destination will reroute messages "sent to this recipient" to SystemRouter.
 *  - As a result: only SystemRouter messages will have this value as both sender and recipient.
 * Note: all bits except for lower 20 bytes are set to 1.
 * Note: TypeCasts.bytes32ToAddress(SYSTEM_ROUTER) == address(0)
 */
bytes32 constant SYSTEM_ROUTER = bytes32(type(uint256).max << 160);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Illusory Systems Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
    uint256 internal constant TREE_DEPTH = 32;
    uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

    /**
     * @notice Struct representing incremental merkle tree. Contains the current branch,
     * while the number of inserted leaves are stored externally.
     **/
    // solhint-disable-next-line ordering
    struct Tree {
        bytes32[TREE_DEPTH] branch;
    }

    /**
     * @notice Inserts `_node` into merkle tree
     * @dev Reverts if tree is full
     * @param _newCount Amount of inserted leaves in the tree after the insertion (i.e. current + 1)
     * @param _node     Element to insert into tree
     **/
    function insert(
        Tree storage _tree,
        uint256 _newCount,
        bytes32 _node
    ) internal {
        require(_newCount <= MAX_LEAVES, "merkle tree full");
        // No need to increase _newCount here,
        // as it is already the amount of leaves after the insertion.
        for (uint256 i = 0; i < TREE_DEPTH; ) {
            if ((_newCount & 1) == 1) {
                _tree.branch[i] = _node;
                return;
            }
            _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
            _newCount >>= 1;
            unchecked {
                ++i;
            }
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /**
     * @notice Calculates and returns`_tree`'s current root given array of zero
     * hashes
     * @param _count    Current amount of inserted leaves in the tree
     * @param _zeroes   Array of zero hashes
     * @return _current Calculated root of `_tree`
     **/
    function rootWithCtx(
        Tree storage _tree,
        uint256 _count,
        bytes32[TREE_DEPTH] memory _zeroes
    ) internal view returns (bytes32 _current) {
        for (uint256 i = 0; i < TREE_DEPTH; ) {
            uint256 _ithBit = (_count >> i) & 0x01;
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_tree.branch[i], _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates and returns`_tree`'s current root
     * @param _count    Current amount of inserted leaves in the tree
     * @return Calculated root of `_tree`
     **/
    function root(Tree storage _tree, uint256 _count) internal view returns (bytes32) {
        return rootWithCtx(_tree, _count, zeroHashes());
    }

    /// @notice Returns array of TREE_DEPTH zero hashes
    /// @return _zeroes Array of TREE_DEPTH zero hashes
    function zeroHashes() internal pure returns (bytes32[TREE_DEPTH] memory _zeroes) {
        _zeroes[0] = Z_0;
        _zeroes[1] = Z_1;
        _zeroes[2] = Z_2;
        _zeroes[3] = Z_3;
        _zeroes[4] = Z_4;
        _zeroes[5] = Z_5;
        _zeroes[6] = Z_6;
        _zeroes[7] = Z_7;
        _zeroes[8] = Z_8;
        _zeroes[9] = Z_9;
        _zeroes[10] = Z_10;
        _zeroes[11] = Z_11;
        _zeroes[12] = Z_12;
        _zeroes[13] = Z_13;
        _zeroes[14] = Z_14;
        _zeroes[15] = Z_15;
        _zeroes[16] = Z_16;
        _zeroes[17] = Z_17;
        _zeroes[18] = Z_18;
        _zeroes[19] = Z_19;
        _zeroes[20] = Z_20;
        _zeroes[21] = Z_21;
        _zeroes[22] = Z_22;
        _zeroes[23] = Z_23;
        _zeroes[24] = Z_24;
        _zeroes[25] = Z_25;
        _zeroes[26] = Z_26;
        _zeroes[27] = Z_27;
        _zeroes[28] = Z_28;
        _zeroes[29] = Z_29;
        _zeroes[30] = Z_30;
        _zeroes[31] = Z_31;
    }

    /**
     * @notice Calculates and returns the merkle root for the given leaf
     * `_item`, a merkle branch, and the index of `_item` in the tree.
     * @param _item Merkle leaf
     * @param _branch Merkle proof
     * @param _index Index of `_item` in tree
     * @return _current Calculated merkle root
     **/
    function branchRoot(
        bytes32 _item,
        bytes32[TREE_DEPTH] memory _branch,
        uint256 _index
    ) internal pure returns (bytes32 _current) {
        _current = _item;
        // Go up the tree levels from leaf to root
        for (uint256 i = 0; i < TREE_DEPTH; ) {
            _current = getParent(_current, _branch[i], _index, i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates and returns the merkle root for the given leaf
     * `_item`, a merkle branch, and the index of `_item` in the tree.
     * @dev This extra function is required for Merkle Trees with flexible height.
     * @param _item Merkle leaf
     * @param _branch Merkle proof
     * @param _index Index of `_item` in tree
     * @return _current Calculated merkle root
     **/
    function branchRoot(
        bytes32 _item,
        bytes32[] memory _branch,
        uint256 _index
    ) internal pure returns (bytes32 _current) {
        _current = _item;
        // Go up the tree levels from leaf to root
        for (uint256 i = 0; i < _branch.length; ) {
            _current = getParent(_current, _branch[i], _index, i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates the parent of a node on the path from one of the leafs to root.
     * @param _node         Node on a path from tree leaf to root
     * @param _sibling      Sibling for a given node
     * @param _leafIndex    Index of the tree leaf
     * @param _nodeHeight   "Level height" for `_node` (ZERO for leafs, TREE_DEPTH for root)
     */
    function getParent(
        bytes32 _node,
        bytes32 _sibling,
        uint256 _leafIndex,
        uint256 _nodeHeight
    ) internal pure returns (bytes32 parent) {
        // Index for `node` on its "tree level" is (leafIndex / 2**height)
        // "Left child" has even index, "right child" has odd index
        if ((_leafIndex >> _nodeHeight) & 1 == 0) {
            // Left child
            return keccak256(bytes.concat(_node, _sibling));
        } else {
            // Right child
            return keccak256(bytes.concat(_sibling, _node));
        }
    }

    // keccak256 zero hashes
    bytes32 internal constant Z_0 =
        hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes32 internal constant Z_1 =
        hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
    bytes32 internal constant Z_2 =
        hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
    bytes32 internal constant Z_3 =
        hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
    bytes32 internal constant Z_4 =
        hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
    bytes32 internal constant Z_5 =
        hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
    bytes32 internal constant Z_6 =
        hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
    bytes32 internal constant Z_7 =
        hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
    bytes32 internal constant Z_8 =
        hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
    bytes32 internal constant Z_9 =
        hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
    bytes32 internal constant Z_10 =
        hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
    bytes32 internal constant Z_11 =
        hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
    bytes32 internal constant Z_12 =
        hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
    bytes32 internal constant Z_13 =
        hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
    bytes32 internal constant Z_14 =
        hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
    bytes32 internal constant Z_15 =
        hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
    bytes32 internal constant Z_16 =
        hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
    bytes32 internal constant Z_17 =
        hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
    bytes32 internal constant Z_18 =
        hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
    bytes32 internal constant Z_19 =
        hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
    bytes32 internal constant Z_20 =
        hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
    bytes32 internal constant Z_21 =
        hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
    bytes32 internal constant Z_22 =
        hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
    bytes32 internal constant Z_23 =
        hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
    bytes32 internal constant Z_24 =
        hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
    bytes32 internal constant Z_25 =
        hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
    bytes32 internal constant Z_26 =
        hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
    bytes32 internal constant Z_27 =
        hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
    bytes32 internal constant Z_28 =
        hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
    bytes32 internal constant Z_29 =
        hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
    bytes32 internal constant Z_30 =
        hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
    bytes32 internal constant Z_31 =
        hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { Header, HeaderLib } from "./Header.sol";
import { Tips, TipsLib } from "./Tips.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Message is a memory over over a formatted message payload.
type Message is bytes29;
/// @dev Attach library functions to Message
using {
    MessageLib.unwrap,
    MessageLib.version,
    MessageLib.header,
    MessageLib.tips,
    MessageLib.body,
    MessageLib.leaf
} for Message global;

/**
 * @notice  Library for versioned formatting the messages used by Origin and Destination.
 */
library MessageLib {
    using HeaderLib for bytes29;
    using TipsLib for bytes29;
    using ByteString for bytes;
    using TypedMemView for bytes29;

    enum Parts {
        Version,
        Header,
        Tips,
        Body
    }

    /**
     * @dev This is only updated if the whole message structure is changed,
     *      i.e. if a new part is added.
     *      If already existing part is changed, the message version does not get bumped.
     */
    uint16 internal constant MESSAGE_VERSION = 1;

    /**
     * @dev Message memory layout
     * [000 .. 002): version            uint16  2 bytes
     * [002 .. 004): header length      uint16  2 bytes (length == AAA - 6)
     * [004 .. 006): tips length        uint16  2 bytes (length == BBB - AAA)
     * [006 .. AAA): header             bytes   ? bytes
     * [AAA .. BBB): tips               bytes   ? bytes
     * [BBB .. CCC): body               bytes   ? bytes (length could be zero)
     */

    uint256 internal constant OFFSET_VERSION = 0;

    /// @dev How much bytes is used for storing the version, or a single offset value
    uint8 internal constant TWO_BYTES = 2;
    /// @dev This value reflects the header offset in the latest message version
    uint16 internal constant OFFSET_HEADER = TWO_BYTES * uint8(type(Parts).max);

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              FORMATTERS                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns formatted message with provided fields
     * @param _header       Formatted header payload
     * @param _tips         Formatted tips payload
     * @param _messageBody  Raw bytes of message body
     * @return Formatted message
     **/
    function formatMessage(
        bytes memory _header,
        bytes memory _tips,
        bytes memory _messageBody
    ) internal pure returns (bytes memory) {
        // Header and Tips are supposed to fit within 65535 bytes
        return
            abi.encodePacked(
                MESSAGE_VERSION,
                uint16(_header.length),
                uint16(_tips.length),
                _header,
                _tips,
                _messageBody
            );
    }

    /**
     * @notice Returns formatted message with provided fields
     * @param _origin               Domain of origin chain
     * @param _sender               Address that sent the message
     * @param _nonce                Message nonce on origin chain
     * @param _destination          Domain of destination chain
     * @param _recipient            Address that will receive the message
     * @param _optimisticSeconds    Optimistic period for message execution
     * @param _tips                 Formatted tips payload
     * @param _messageBody          Raw bytes of message body
     * @return Formatted message
     **/
    function formatMessage(
        uint32 _origin,
        bytes32 _sender,
        uint32 _nonce,
        uint32 _destination,
        bytes32 _recipient,
        uint32 _optimisticSeconds,
        bytes memory _tips,
        bytes memory _messageBody
    ) internal pure returns (bytes memory) {
        return
            formatMessage(
                HeaderLib.formatHeader(
                    _origin,
                    _sender,
                    _nonce,
                    _destination,
                    _recipient,
                    _optimisticSeconds
                ),
                _tips,
                _messageBody
            );
    }

    /**
     * @notice Returns a Message view over for the given payload.
     * @dev Will revert if the payload is not a message payload.
     */
    function castToMessage(bytes memory _payload) internal pure returns (Message) {
        return castToMessage(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a Message view.
     * @dev Will revert if the memory view is not over a message payload.
     */
    function castToMessage(bytes29 _view) internal pure returns (Message) {
        require(isMessage(_view), "Not a message payload");
        return Message.wrap(_view);
    }

    /**
     * @notice Checks that a payload is a formatted Message.
     */
    function isMessage(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Check if version and lengths exist in the payload
        if (length < OFFSET_HEADER) return false;
        // Check message version
        if (_getVersion(_view) != MESSAGE_VERSION) return false;

        uint256 headerLength = _getLen(_view, Parts.Header);
        uint256 tipsLength = _getLen(_view, Parts.Tips);
        // Header and Tips need to exist
        // Body could be empty, thus >
        if (OFFSET_HEADER + headerLength + tipsLength > length) return false;

        // Check header for being a formatted header payload
        // Check tips for being a formatted tips payload
        if (!_getHeader(_view).isHeader() || !_getTips(_view).isTips()) return false;
        return true;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Message _msg) internal pure returns (bytes29) {
        return Message.unwrap(_msg);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           MESSAGE SLICING                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns message's version field.
    function version(Message _msg) internal pure returns (uint16) {
        // Get the underlying memory view
        bytes29 _view = _msg.unwrap();
        return _getVersion(_view);
    }

    /// @notice Returns message's header field as a Header view.
    function header(Message _msg) internal pure returns (Header) {
        bytes29 _view = _msg.unwrap();
        return _getHeader(_view).castToHeader();
    }

    /// @notice Returns message's tips field as a Tips view.
    function tips(Message _msg) internal pure returns (Tips) {
        bytes29 _view = _msg.unwrap();
        return _getTips(_view).castToTips();
    }

    /// @notice Returns message's body field as a generic memory view.
    function body(Message _msg) internal pure returns (bytes29) {
        bytes29 _view = _msg.unwrap();
        // Determine index where message body payload starts
        uint256 index = OFFSET_HEADER + _getLen(_view, Parts.Header) + _getLen(_view, Parts.Tips);
        return _view.sliceFrom({ _index: index, newType: 0 });
    }

    /// @notice Returns message's hash: a leaf to be inserted in the Merkle tree.
    function leaf(Message _msg) internal pure returns (bytes32) {
        bytes29 _view = _msg.unwrap();
        return _view.keccak();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           PRIVATE HELPERS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Returns length for a given part of the message
    /// without checking if the payload is properly formatted.
    function _getLen(bytes29 _view, Parts _part) private pure returns (uint256) {
        return _view.indexUint(uint256(_part) * TWO_BYTES, TWO_BYTES);
    }

    /// @dev Returns a version field without checking if the payload is properly formatted.
    function _getVersion(bytes29 _view) private pure returns (uint16) {
        return uint16(_view.indexUint(OFFSET_VERSION, 2));
    }

    /// @dev Returns a generic memory view over the header field without checking
    /// if the whole payload or the header are properly formatted.
    function _getHeader(bytes29 _view) private pure returns (bytes29) {
        uint256 length = _getLen(_view, Parts.Header);
        return _view.slice({ _index: OFFSET_HEADER, _len: length, newType: 0 });
    }

    /// @dev Returns a generic memory view over the tips field without checking
    /// if the whole payload or the tips are properly formatted.
    function _getTips(bytes29 _view) private pure returns (bytes29) {
        // Determine index where tips payload starts
        uint256 indexFrom = OFFSET_HEADER + _getLen(_view, Parts.Header);
        uint256 length = _getLen(_view, Parts.Tips);
        return _view.slice({ _index: indexFrom, _len: length, newType: 0 });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { STATE_LENGTH } from "./Constants.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev State is a memory view over a formatted state payload.
type State is bytes29;
/// @dev Attach library functions to State
using {
    StateLib.unwrap,
    StateLib.equalToOrigin,
    StateLib.hash,
    StateLib.subLeafs,
    StateLib.toSummitState,
    StateLib.root,
    StateLib.origin,
    StateLib.nonce,
    StateLib.blockNumber,
    StateLib.timestamp
} for State global;

/// @dev Struct representing State, as it is stored in the Origin contract.
struct OriginState {
    bytes32 root;
    uint40 blockNumber;
    uint40 timestamp;
    // 176 bits left for tight packing
}
/// @dev Attach library functions to OriginState
using { StateLib.formatOriginState } for OriginState global;

/// @dev Struct representing State, as it is stored in the Summit contract.
struct SummitState {
    bytes32 root;
    uint32 origin;
    uint32 nonce;
    uint40 blockNumber;
    uint40 timestamp;
    // 112 bits left for tight packing
}
/// @dev Attach library functions to SummitState
using { StateLib.formatSummitState } for SummitState global;

library StateLib {
    using ByteString for bytes;
    using TypedMemView for bytes29;

    /**
     * @dev State structure represents the state of Origin contract at some point of time.
     * State is structured in a way to track the updates of the Origin Merkle Tree. State includes
     * root of the Origin Merkle Tree, origin domain and some additional metadata.
     *
     * Hash of every dispatched message is inserted in the Origin Merkle Tree, which changes the
     * value of Origin Merkle Root (which is the root for the mentioned tree).
     * Origin has a single Merkle Tree for all messages, regardless of their destination domain.
     * This leads to Origin state being updated if and only if a message was dispatched in a block.
     *
     * Origin contract is a "source of truth" for states: a state is considered "valid" in its Origin,
     * if it matches the state of the Origin contract after the N-th (nonce) message was dispatched.
     *
     * @dev Memory layout of State fields
     * [000 .. 032): root           bytes32 32 bytes    Root of the Origin Merkle Tree
     * [032 .. 036): origin         uint32   4 bytes    Domain where Origin is located
     * [036 .. 040): nonce          uint32   4 bytes    Amount of dispatched messages
     * [040 .. 045): blockNumber    uint40   5 bytes    Block of last dispatched message
     * [045 .. 050): timestamp      uint40   5 bytes    Time of last dispatched message
     *
     * The variables below are not supposed to be used outside of the library directly.
     */

    uint256 private constant OFFSET_ROOT = 0;
    uint256 private constant OFFSET_ORIGIN = 32;
    uint256 private constant OFFSET_NONCE = 36;
    uint256 private constant OFFSET_BLOCK_NUMBER = 40;
    uint256 private constant OFFSET_TIMESTAMP = 45;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                STATE                                 ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted State payload with provided fields
     * @param _root         New merkle root
     * @param _origin       Domain of Origin's chain
     * @param _nonce        Nonce of the merkle root
     * @param _blockNumber  Block number when root was saved in Origin
     * @param _timestamp    Block timestamp when root was saved in Origin
     * @return Formatted state
     **/
    function formatState(
        bytes32 _root,
        uint32 _origin,
        uint32 _nonce,
        uint40 _blockNumber,
        uint40 _timestamp
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_root, _origin, _nonce, _blockNumber, _timestamp);
    }

    /**
     * @notice Returns a State view over the given payload.
     * @dev Will revert if the payload is not a state.
     */
    function castToState(bytes memory _payload) internal pure returns (State) {
        return castToState(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a State view.
     * @dev Will revert if the memory view is not over a state.
     */
    function castToState(bytes29 _view) internal pure returns (State) {
        require(isState(_view), "Not a state");
        return State.wrap(_view);
    }

    /// @notice Checks that a payload is a formatted State.
    function isState(bytes29 _view) internal pure returns (bool) {
        return _view.len() == STATE_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(State _state) internal pure returns (bytes29) {
        return State.unwrap(_state);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             ORIGIN STATE                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted State payload with provided fields.
     * @param _origin       Domain of Origin's chain
     * @param _nonce        Nonce of the merkle root
     * @param _originState  State struct as it is stored in Origin contract
     * @return Formatted state
     */
    function formatOriginState(
        OriginState memory _originState,
        uint32 _origin,
        uint32 _nonce
    ) internal pure returns (bytes memory) {
        return
            formatState({
                _root: _originState.root,
                _origin: _origin,
                _nonce: _nonce,
                _blockNumber: _originState.blockNumber,
                _timestamp: _originState.timestamp
            });
    }

    /// @notice Returns a struct to save in the Origin contract.
    /// Current block number and timestamp are used.
    function originState(bytes32 currentRoot) internal view returns (OriginState memory state) {
        state.root = currentRoot;
        state.blockNumber = uint40(block.number);
        state.timestamp = uint40(block.timestamp);
    }

    /// @notice Checks that a state and its Origin representation are equal.
    function equalToOrigin(State _state, OriginState memory _originState)
        internal
        pure
        returns (bool)
    {
        return
            _state.root() == _originState.root &&
            _state.blockNumber() == _originState.blockNumber &&
            _state.timestamp() == _originState.timestamp;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             SUMMIT STATE                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted State payload with provided fields.
     * @param _summitState  State struct as it is stored in Summit contract
     * @return Formatted state
     */
    function formatSummitState(SummitState memory _summitState)
        internal
        pure
        returns (bytes memory)
    {
        return
            formatState({
                _root: _summitState.root,
                _origin: _summitState.origin,
                _nonce: _summitState.nonce,
                _blockNumber: _summitState.blockNumber,
                _timestamp: _summitState.timestamp
            });
    }

    /// @notice Returns a struct to save in the Summit contract.
    function toSummitState(State _state) internal pure returns (SummitState memory state) {
        state.root = _state.root();
        state.origin = _state.origin();
        state.nonce = _state.nonce();
        state.blockNumber = _state.blockNumber();
        state.timestamp = _state.timestamp();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            STATE HASHING                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns the hash of the State.
    /// @dev We are using the Merkle Root of a tree with two leafs (see below) as state hash.
    function hash(State _state) internal pure returns (bytes32) {
        (bytes32 _leftLeaf, bytes32 _rightLeaf) = _state.subLeafs();
        // Final hash is the parent of these leafs
        return keccak256(bytes.concat(_leftLeaf, _rightLeaf));
    }

    /// @notice Returns "sub-leafs" of the State. Hash of these "sub leafs" is going to be used
    /// as a "state leaf" in the "Snapshot Merkle Tree".
    /// This enables proving that leftLeaf = (root, origin) was a part of the "Snapshot Merkle Tree",
    /// by combining `rightLeaf` with the remainder of the "Snapshot Merkle Proof".
    function subLeafs(State _state) internal pure returns (bytes32 _leftLeaf, bytes32 _rightLeaf) {
        bytes29 _view = _state.unwrap();
        // Left leaf is (root, origin)
        _leftLeaf = _view.prefix({ _len: OFFSET_NONCE, newType: 0 }).keccak();
        // Right leaf is (metadata), or (nonce, blockNumber, timestamp)
        _rightLeaf = _view.sliceFrom({ _index: OFFSET_NONCE, newType: 0 }).keccak();
    }

    /// @notice Returns the left "sub-leaf" of the State.
    function leftLeaf(bytes32 _root, uint32 _origin) internal pure returns (bytes32) {
        // We use encodePacked here to simulate the State memory layout
        return keccak256(abi.encodePacked(_root, _origin));
    }

    /// @notice Returns the right "sub-leaf" of the State.
    function rightLeaf(
        uint32 _nonce,
        uint40 _blockNumber,
        uint40 _timestamp
    ) internal pure returns (bytes32) {
        // We use encodePacked here to simulate the State memory layout
        return keccak256(abi.encodePacked(_nonce, _blockNumber, _timestamp));
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            STATE SLICING                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns a historical Merkle root from the Origin contract.
    function root(State _state) internal pure returns (bytes32) {
        bytes29 _view = _state.unwrap();
        return _view.index({ _index: OFFSET_ROOT, _bytes: 32 });
    }

    /// @notice Returns domain of chain where the Origin contract is deployed.
    function origin(State _state) internal pure returns (uint32) {
        bytes29 _view = _state.unwrap();
        return uint32(_view.indexUint({ _index: OFFSET_ORIGIN, _bytes: 4 }));
    }

    /// @notice Returns nonce of Origin contract at the time, when `root` was the Merkle root.
    function nonce(State _state) internal pure returns (uint32) {
        bytes29 _view = _state.unwrap();
        return uint32(_view.indexUint({ _index: OFFSET_NONCE, _bytes: 4 }));
    }

    /// @notice Returns a block number when `root` was saved in Origin.
    function blockNumber(State _state) internal pure returns (uint40) {
        bytes29 _view = _state.unwrap();
        return uint40(_view.indexUint({ _index: OFFSET_BLOCK_NUMBER, _bytes: 5 }));
    }

    /// @notice Returns a block timestamp when `root` was saved in Origin.
    /// @dev This is the timestamp according to the origin chain.
    function timestamp(State _state) internal pure returns (uint40) {
        bytes29 _view = _state.unwrap();
        return uint40(_view.indexUint({ _index: OFFSET_TIMESTAMP, _bytes: 5 }));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TypedMemView } from "./TypedMemView.sol";

library TypeCasts {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
        _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
    }

    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.12;

library TypedMemView {
    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifier onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.

    // The null view
    bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    /**
     * @dev Memory layout for bytes29
     * TODO (Chi): with the user defined types storing type is no longer necessary.
     * Update the library, transforming bytes29 to bytes24 in the process.
     * [000..005)   type     5 bytes    Type flag for the pointer
     * [005..017)   loc     12 bytes    Memory address of underlying bytes
     * [017..029)   len     12 bytes    Length of underlying bytes
     * [029..032)   empty    3 bytes    Not used
     */
    uint256 public constant BITS_TYPE = 40;
    uint256 public constant BITS_LOC = 96;
    uint256 public constant BITS_LEN = 96;
    uint256 public constant BITS_EMPTY = 24;

    // `SHIFT_X` is how much bits to shift for `X` to be in the very bottom bits
    uint256 public constant SHIFT_LEN = BITS_EMPTY; // 24
    uint256 public constant SHIFT_LOC = SHIFT_LEN + BITS_LEN; // 24 + 96 = 120
    uint256 public constant SHIFT_TYPE = SHIFT_LOC + BITS_LOC; // 24 + 96 + 96 = 216
    // Bitmask for the lowest 96 bits
    uint256 public constant LOW_96_BITS_MASK = type(uint96).max;

    // For nibble encoding
    bytes private constant NIBBLE_LOOKUP = "0123456789abcdef";

    /**
     * @notice Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _byte     The byte
     * @return _char    The encoded hex character
     */
    function nibbleHex(uint8 _byte) internal pure returns (uint8 _char) {
        uint8 _nibble = _byte & 0x0f; // keep bottom 4 bits, zero out top 4 bits
        _char = uint8(NIBBLE_LOOKUP[_nibble]);
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }

        // abusing underflow here =_=
        for (uint8 i = 15; i < 255; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            second |= byteHex(_byte);
            if (i != 0) {
                second <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v =
            ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v =
            ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v =
            ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v =
            ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        // 0x800...00 binary representation is 100...00
        // sar stands for "signed arithmetic shift": https://en.wikipedia.org/wiki/Arithmetic_shift
        // sar(N-1, 100...00) = 11...100..00, with exactly N highest bits set to 1
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mask := sar(
                sub(_len, 1),
                0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    // solhint-disable-next-line ordering
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {
            return false;
        }
        uint256 _end = end(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // View is valid if ("upper bound" <= "unallocated memory pointer")
            // Upper bound is exclusive, hence "<="
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // How many bits are the "type bits" occupying
        uint256 _bitsType = BITS_TYPE;
        // How many bits are the "type bits" shifted from the bottom
        uint256 _shiftType = SHIFT_TYPE;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // shift off the "type bits" (shift left, then sift right)
            newView := or(newView, shr(_bitsType, shl(_bitsType, memView)))
            // set the new "type bits" (shift left, then OR)
            newView := or(newView, shl(_shiftType, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) private pure returns (bytes29 newView) {
        uint256 _bitsLoc = BITS_LOC;
        uint256 _bitsLen = BITS_LEN;
        uint256 _bitsEmpty = BITS_EMPTY;
        // Ref memory layout
        // [000..005) 5 bytes of type
        // [005..017) 12 bytes of location
        // [017..029) 12 bytes of length
        // last 3 bits are blank and dropped in typecast
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // insert `type`, shift to prepare empty bits for `loc`
            newView := shl(_bitsLoc, or(newView, _type))
            // insert `loc`, shift to prepare empty bits for `len`
            newView := shl(_bitsLen, or(newView, _loc))
            // insert `len`, shift to insert 3 blank lowest bits
            newView := shl(_bitsEmpty, or(newView, _len))
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        // Make sure that a view is not constructed that points to unallocated memory
        // as this could be indicative of a buffer overflow attack
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;
        // `bytes arr` is stored in memory in the following way
        // 1. First, uint256 arr.length is stored. That requires 32 bytes (0x20).
        // 2. Then, the array data is stored.
        uint256 _loc;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // We add 0x20, so that the view starts exactly where the array data starts
            _loc := add(arr, 0x20)
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        // How many bits are the "type bits" shifted from the bottom
        uint256 _shiftType = SHIFT_TYPE;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "type bits". "type bits" are occupying
            // the highest bits, so all that's left is "type bits", OR is not required.
            _type := shr(_shiftType, memView)
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        // Check that the highest 5 bytes are equal: xor and shift out lower 27 bytes
        return (left ^ right) >> SHIFT_TYPE == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        // How many bits are the "loc bits" shifted from the bottom
        uint256 _shiftLoc = SHIFT_LOC;
        // Mask for the bottom 96 bits
        uint256 _uint96Mask = LOW_96_BITS_MASK;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "loc bits".
            // Then use the lowest 96 bits to determine `loc` by applying the bit-mask.
            _loc := and(shr(_shiftLoc, memView), _uint96Mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        // returning ceil(length / 32.0)
        return (uint256(len(memView)) + 31) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        // How many bits are the "len bits" shifted from the bottom
        uint256 _shiftLen = SHIFT_LEN;
        // Mask for the bottom 96 bits
        uint256 _uint96Mask = LOW_96_BITS_MASK;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "len bits".
            // Then use the lowest 96 bits to determine `len` by applying the bit-mask.
            _len := and(shr(_shiftLen, memView), _uint96Mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        unchecked {
            return loc(memView) + len(memView);
        }
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(
        bytes29 memView,
        uint256 _index,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing
     *                  bytes from `_index` to end(memView).
     * @param memView   The view
     * @param _index    The start index
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function sliceFrom(
        bytes29 memView,
        uint256 _index,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, _index, len(memView) - _index, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The 32 byte result
     */
    function index(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (bytes32 result) {
        if (_bytes == 0) {
            return bytes32(0);
        }
        if (_index + _bytes > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "Index: more than 32 bytes");

        uint8 bitLength;
        unchecked {
            bitLength = _bytes * 8;
        }
        uint256 _loc = loc(memView);
        // Get a mask with `bitLength` highest bits set
        uint256 _mask = leftMask(bitLength);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load a full word using index offset, and apply mask to ignore non-relevant bytes
            result := and(mload(add(_loc, _index)), _mask)
        }
    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view have >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        // `index()` returns left-aligned `_bytes`, while integers are right-aligned
        // Shifting here to right-align with the full 32 bytes word
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexLEUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`.
     *                  Requires that the view have >= 20 bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        // index 20 bytes as `uint160`, and then cast to `address`
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            digest := mload(ptr)
        }
        require(res, "sha2: out of gas");
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            // rmd160 precompile is 0x03
            res := and(res, staticcall(gas(), 0x03, ptr, 0x20, ptr, 0x20))
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
        require(res, "hash160: out of gas");
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            res := and(res, staticcall(gas(), 0x02, ptr, 0x20, ptr, 0x20))
            digest := mload(ptr)
        }
        require(res, "hash256: out of gas");
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return
            (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "copyTo: Null pointer deref");
        require(isValid(memView), "copyTo: Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

            // use the identity precompile (0x04) to copy
            res := staticcall(gas(), 0x04, _oldLoc, _len, _newLoc, _len)
        }
        require(res, "identity: out of gas");

        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory,
     *                  returning a `bytes` pointing to the new memory.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unchecked {
            unsafeCopyTo(memView, ptr + 0x20);
        }
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location)
        private
        view
        returns (bytes29 unsafeView)
    {
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i++) {
            bytes29 memView = memViews[i];
            unchecked {
                unsafeCopyTo(memView, _location + _offset);
                _offset += len(memView);
            }
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView;
        unchecked {
            _newView = unsafeJoin(memViews, ptr + 0x20);
        }
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // store the length
            mstore(ptr, _written)
            // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract DomainContext {
    /// @notice Domain of the local chain, set once upon contract creation
    uint32 public immutable localDomain;

    /**
     * @notice Ensures that a domain matches the local domain.
     */
    modifier onlyLocalDomain(uint32 _domain) {
        _assertLocalDomain(_domain);
        _;
    }

    constructor(uint32 _domain) {
        localDomain = _domain;
    }

    function _assertLocalDomain(uint32 _domain) internal view {
        require(_domain == localDomain, "!localDomain");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice A collection of events emitted by the Destination contract
abstract contract DestinationEvents {
    /**
     * @notice Emitted when a snapshot is accepted by the Destination contract.
     * @param domain        Domain where the signed Notary is active
     * @param notary        Notary who signed the attestation
     * @param attestation   Raw payload with attestation data
     * @param attSignature  Notary signature for the attestation
     */
    event AttestationAccepted(uint32 domain, address notary, bytes attestation, bytes attSignature);

    /**
     * @notice Emitted when message is executed.
     * @param remoteDomain  Remote domain where message originated
     * @param messageHash   The keccak256 hash of the message that was executed
     */
    event Executed(uint32 indexed remoteDomain, bytes32 indexed messageHash);

    /**
     * @notice Emitted when tips are stored.
     * @param notary        Notary who signed the Snapshot Root used for proving the message
     * @param tips          Raw payload with tips paid for the off-chain agents
     */
    event TipsStored(address indexed notary, bytes tips);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ORIGIN_TREE_DEPTH } from "../libs/Constants.sol";

interface InterfaceDestination {
    /**
     * @notice Attempts to prove inclusion of message into one of Snapshot Merkle Trees,
     * previously submitted to this contract in a form of a signed Attestation.
     * Proven message is immediately executed by passing its contents to the specified recipient.
     * @dev Will revert if any of these is true:
     *  - Message payload is not properly formatted.
     *  - Snapshot root (reconstructed from message hash and proofs) is unknown
     *  - Snapshot root is known, but was submitted by an inactive Notary
     *  - Snapshot root is known, but optimistic period for a message hasn't passed
     *  - Recipient doesn't implement a `handle` method (refer to IMessageRecipient.sol)
     *  - Recipient reverted upon receiving a message
     * Note: refer to libs/State.sol for details about Origin State's sub-leafs.
     * @param _message      Raw payload with a formatted message to execute
     * @param _originProof  Proof of inclusion of message in the Origin Merkle Tree
     * @param _snapProof    Proof of inclusion of Origin State's Left Leaf into Snapshot Merkle Tree
     * @param _stateIndex   Index of Origin State in the Snapshot
     */
    function execute(
        bytes memory _message,
        bytes32[ORIGIN_TREE_DEPTH] calldata _originProof,
        bytes32[] calldata _snapProof,
        uint256 _stateIndex
    ) external;

    /**
     * @notice Submit an Attestation signed by a Notary.
     * @dev Will revert if any of these is true:
     *  - Attestation payload is not properly formatted.
     *  - Attestation signer is not an active Notary for local domain.
     *  - Attestation's snapshot root has been previously submitted.
     */
    function submitAttestation(bytes memory _attPayload, bytes memory _attSignature)
        external
        returns (bool wasAccepted);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        uint32 _nonce,
        bytes32 _sender,
        uint256 _rootTimestamp,
        bytes memory _message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { Attestation, DestinationAttestation } from "../libs/Attestation.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { IAttestationHub } from "../interfaces/IAttestationHub.sol";

/**
 * @notice Hub to accept and save attestations.
 */
abstract contract AttestationHub is IAttestationHub {
    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               STORAGE                                ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Tracks all accepted Notary attestations
    // (root => attestation)
    mapping(bytes32 => DestinationAttestation) private rootAttestations;

    /// @dev All snapshot roots from the accepted Notary attestations
    bytes32[] private roots;

    /// @dev gap for upgrade safety
    uint256[48] private __GAP; // solhint-disable-line var-name-mixedcase

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                VIEWS                                 ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @inheritdoc IAttestationHub
    function attestationsAmount() external view returns (uint256) {
        return roots.length;
    }

    /// @inheritdoc IAttestationHub
    function getAttestation(uint256 _index)
        external
        view
        returns (bytes32 root, DestinationAttestation memory destAtt)
    {
        require(_index < roots.length, "Index out of range");
        root = roots[_index];
        destAtt = rootAttestations[root];
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             ACCEPT DATA                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Accepts an Attestation signed by a Notary.
    /// It is assumed that the Notary signature has been checked outside of this contract.
    function _acceptAttestation(Attestation _att, address _notary) internal {
        bytes32 root = _att.root();
        require(_rootAttestation(root).isEmpty(), "Root already exists");
        rootAttestations[root] = _att.toDestinationAttestation(_notary);
        roots.push(root);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                         CHECK STATEMENT DATA                         ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Returns the saved attestation for the "Snapshot Merkle Root".
    /// Will return an empty struct, if the root hasn't been submitted in a Notary attestation yet.
    function _rootAttestation(bytes32 _root) internal view returns (DestinationAttestation memory) {
        return rootAttestations[_root];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { Attestation, AttestationLib } from "../libs/Attestation.sol";
import { Snapshot, SnapshotLib } from "../libs/Snapshot.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { AgentRegistry } from "../system/AgentRegistry.sol";
import { Version0_0_2 } from "../Version.sol";
// ═════════════════════════════ EXTERNAL IMPORTS ══════════════════════════════
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice This abstract contract is used for verifying Guards and Notaries
 * signature over several type of statements such as:
 * - Attestations
 * - Snapshots
 * - Reports
 * Several checks are performed in StatementHub, abstracting it away from the child contracts:
 * - Statement being properly formatted
 * - Signer being an active agent
 * - Signer being allowed to sign the particular type of statement
 */
abstract contract StatementHub is AgentRegistry, Version0_0_2 {
    using AttestationLib for bytes;
    using SnapshotLib for bytes;

    /**
     * @dev Recovers a signer from a hashed message, and a EIP-191 signature for it.
     * Will revert, if the signer is not an active agent.
     * @param _hashedStatement  Hash of the statement that was signed by an Agent
     * @param _signature        Agent signature for the hashed statement
     * @return domain   Domain where the signed Agent is active
     * @return agent    Agent that signed the statement
     */
    function _recoverAgent(bytes32 _hashedStatement, bytes memory _signature)
        internal
        view
        returns (uint32 domain, address agent)
    {
        bytes32 ethSignedMsg = ECDSA.toEthSignedMessageHash(_hashedStatement);
        agent = ECDSA.recover(ethSignedMsg, _signature);
        bool isActive;
        (isActive, domain) = _isActiveAgent(agent);
        require(isActive, "Not an active agent");
    }

    /**
     * @dev Internal function to verify the signed attestation payload.
     * Reverts if either of this is true:
     *  - Attestation payload is not properly formatted.
     *  - Attestation signer is not an active Notary.
     * @param _attPayload       Raw payload with attestation data
     * @param _attSignature     Notary signature for the attestation
     * @return attestation      Typed memory view over attestation payload
     * @return domain           Domain where the signed Notary is active
     * @return notary           Notary that signed the snapshot
     */
    function _verifyAttestation(bytes memory _attPayload, bytes memory _attSignature)
        internal
        view
        returns (
            Attestation attestation,
            uint32 domain,
            address notary
        )
    {
        // This will revert if payload is not a formatted attestation
        attestation = _attPayload.castToAttestation();
        // This will revert if signer is not an active agent
        (domain, notary) = _recoverAgent(attestation.hash(), _attSignature);
        // Attestation signer needs to be a Notary, not a Guard
        require(domain != 0, "Signer is not a Notary");
    }

    /**
     * @dev Internal function to verify the signed snapshot payload.
     * Reverts if either of this is true:
     *  - Snapshot payload is not properly formatted.
     *  - Snapshot signer is not an active Agent.
     * @param _snapPayload      Raw payload with snapshot data
     * @param _snapSignature    Agent signature for the snapshot
     * @return snapshot         Typed memory view over snapshot payload
     * @return domain           Domain where the signed Agent is active
     * @return agent            Agent that signed the snapshot
     */
    function _verifySnapshot(bytes memory _snapPayload, bytes memory _snapSignature)
        internal
        view
        returns (
            Snapshot snapshot,
            uint32 domain,
            address agent
        )
    {
        // This will revert if payload is not a formatted snapshot
        snapshot = _snapPayload.castToSnapshot();
        // This will revert if signer is not an active agent
        (domain, agent) = _recoverAgent(snapshot.hash(), _snapSignature);
        // Guards and Notaries for all domains could sign Snapshots, no further checks are needed.
    }

    /**
     * @dev Internal function to verify that snapshot root matches the root from Attestation.
     * Reverts if either of this is true:
     *  - Snapshot payload is not properly formatted.
     *  - Attestation root is not equal to root derived from the snapshot.
     * @param _att          Typed memory view over Attestation
     * @param _snapPayload  Raw payload with snapshot data
     * @return snapshot     Typed memory view over snapshot payload
     */
    function _verifySnapshotRoot(Attestation _att, bytes memory _snapPayload)
        internal
        pure
        returns (Snapshot snapshot)
    {
        // This will revert if payload is not a formatted snapshot
        snapshot = _snapPayload.castToSnapshot();
        require(_att.root() == snapshot.root(), "Incorrect snapshot root");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { AgentInfo, SystemEntity } from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { AgentRegistry } from "./AgentRegistry.sol";
import { ISystemContract, SystemContract } from "./SystemContract.sol";
import { InterfaceSystemRouter } from "../interfaces/InterfaceSystemRouter.sol";

/**
 * @notice Shared agents registry utilities for Origin, Destination.
 * Agents are added/removed via a system call from a local BondingManager.
 */
abstract contract SystemRegistry is AgentRegistry, SystemContract {
    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          SYSTEM ROUTER ONLY                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Receive a system call indicating the off-chain agent needs to be slashed.
     * @dev Must be called from a local BondingManager. Therefore
     * `uint256 _rootSubmittedAt` is ignored.
     * @param _callOrigin       Domain where the system call originated
     * @param _caller           Entity which performed the system call
     * @param _info             Information about agent to slash
     */
    function slashAgent(
        uint256,
        uint32 _callOrigin,
        SystemEntity _caller,
        AgentInfo memory _info
    ) external onlySystemRouter onlyLocalBondingManager(_callOrigin, _caller) {
        /// @dev Agent was slashed elsewhere. Slash Agent in this Registry, don't send a slashAgent system call
        _slashAgent(_info.domain, _info.account, false);
    }

    /// @inheritdoc ISystemContract
    function syncAgent(
        uint256,
        uint32 _callOrigin,
        SystemEntity _caller,
        AgentInfo memory _info
    ) external onlySystemRouter onlyLocalBondingManager(_callOrigin, _caller) {
        /// @dev Must be called from a local BondingManager. Hence `_rootSubmittedAt` is ignored.
        _updateAgentStatus(_info);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           INTERNAL HELPERS                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function _updateAgentStatus(AgentInfo memory _info) internal {
        if (_info.bonded) {
            _addAgent(_info.domain, _info.account);
        } else {
            _removeAgent(_info.domain, _info.account);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TypedMemView } from "./TypedMemView.sol";

/// @dev CallData is a memory view over the payload to be used for an external call, i.e.
/// recipient.call(callData). Its length is always (4 + 32 * N) bytes:
/// - First 4 bytes represent the function selector.
/// - 32 * N bytes represent N words that function arguments occupy.
type CallData is bytes29;
/// @dev Signature is a memory view over a "65 bytes" array representing a ECDSA signature.
type Signature is bytes29;

library ByteString {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    /**
     * @dev non-compact ECDSA signatures are enforced as of OZ 4.7.3
     *
     *      Signature payload memory layout
     * [000 .. 032) r   bytes32 32 bytes
     * [032 .. 064) s   bytes32 32 bytes
     * [064 .. 065) v   uint8    1 byte
     */
    uint256 internal constant SIGNATURE_LENGTH = 65;
    uint256 internal constant OFFSET_R = 0;
    uint256 internal constant OFFSET_S = 32;
    uint256 internal constant OFFSET_V = 64;

    /**
     * @dev Calldata memory layout
     * [000 .. 004) selector    bytes4  4 bytes
     *      Optional: N function arguments
     * [004 .. 036) arg1        bytes32 32 bytes
     *      ..
     * [AAA .. END) argN        bytes32 32 bytes
     */
    uint256 internal constant SELECTOR_LENGTH = 4;
    uint256 internal constant OFFSET_SELECTOR = 0;
    uint256 internal constant OFFSET_ARGUMENTS = SELECTOR_LENGTH;

    /**
     * @notice Returns a memory view over the given payload, treating it as raw bytes.
     * @dev Shortcut for .ref(0) - to be deprecated once "uint40 type" is removed from bytes29.
     */
    function castToRawBytes(bytes memory _payload) internal pure returns (bytes29) {
        return _payload.ref({ newType: 0 });
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              SIGNATURE                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Constructs the signature payload from the given values.
     * @dev Using ByteString.formatSignature({r: r, s: s, v: v}) will make sure
     * that params are given in the right order.
     */
    function formatSignature(
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }

    /**
     * @notice Returns a Signature view over for the given payload.
     * @dev Will revert if the payload is not a signature.
     */
    function castToSignature(bytes memory _payload) internal pure returns (Signature) {
        return castToSignature(castToRawBytes(_payload));
    }

    /**
     * @notice Casts a memory view to a Signature view.
     * @dev Will revert if the memory view is not over a signature.
     */
    function castToSignature(bytes29 _view) internal pure returns (Signature) {
        require(isSignature(_view), "Not a signature");
        return Signature.wrap(_view);
    }

    /**
     * @notice Checks that a byte string is a signature
     */
    function isSignature(bytes29 _view) internal pure returns (bool) {
        return _view.len() == SIGNATURE_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Signature _signature) internal pure returns (bytes29) {
        return Signature.unwrap(_signature);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          SIGNATURE SLICING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Unpacks signature payload into (r, s, v) parameters.
    /// @dev Make sure to verify signature length with isSignature() beforehand.
    function toRSV(Signature _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // Get the underlying memory view
        bytes29 _view = unwrap(_signature);
        r = _view.index({ _index: OFFSET_R, _bytes: 32 });
        s = _view.index({ _index: OFFSET_S, _bytes: 32 });
        v = uint8(_view.indexUint({ _index: OFFSET_V, _bytes: 1 }));
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               CALLDATA                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a CallData view over for the given payload.
     * @dev Will revert if the memory view is not over a calldata.
     */
    function castToCallData(bytes memory _payload) internal pure returns (CallData) {
        return castToCallData(castToRawBytes(_payload));
    }

    /**
     * @notice Casts a memory view to a CallData view.
     * @dev Will revert if the memory view is not over a calldata.
     */
    function castToCallData(bytes29 _view) internal pure returns (CallData) {
        require(isCallData(_view), "Not a calldata");
        return CallData.wrap(_view);
    }

    /**
     * @notice Checks that a byte string is a valid calldata, i.e.
     * a function selector, followed by arbitrary amount of arguments.
     */
    function isCallData(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Calldata should at least have a function selector
        if (length < SELECTOR_LENGTH) return false;
        // The remainder of the calldata should be exactly N words (N >= 0), i.e.
        // (length - SELECTOR_LENGTH) % 32 == 0
        // We're using logical AND here to speed it up a bit
        return (length - SELECTOR_LENGTH) & 31 == 0;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(CallData _callData) internal pure returns (bytes29) {
        return CallData.unwrap(_callData);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           CALLDATA SLICING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns amount of memory words (32 byte chunks) the function arguments
     * occupy in the calldata.
     * @dev This might differ from amount of arguments supplied, if any of the arguments
     * occupies more than one memory slot. It is true, however, that argument part of the payload
     * occupies exactly N words, even for dynamic types like `bytes`
     */
    function argumentWords(CallData _callData) internal pure returns (uint256) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        // Equivalent of (length - SELECTOR_LENGTH) / 32
        return (_view.len() - SELECTOR_LENGTH) >> 5;
    }

    /// @notice Returns selector for the provided calldata.
    function callSelector(CallData _callData) internal pure returns (bytes29) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        return _view.slice({ _index: OFFSET_SELECTOR, _len: SELECTOR_LENGTH, newType: 0 });
    }

    /// @notice Returns abi encoded arguments for the provided calldata.
    function arguments(CallData _callData) internal pure returns (bytes29) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        return _view.sliceFrom({ _index: OFFSET_ARGUMENTS, newType: 0 });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { TypeCasts } from "./TypeCasts.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Header is a memory over over a formatted message header payload.
type Header is bytes29;
/// @dev Attach library functions to Header
using {
    HeaderLib.unwrap,
    HeaderLib.version,
    HeaderLib.origin,
    HeaderLib.sender,
    HeaderLib.nonce,
    HeaderLib.destination,
    HeaderLib.recipient,
    HeaderLib.optimisticSeconds,
    HeaderLib.recipientAddress
} for Header global;

/**
 * @notice Library for versioned formatting [the header part]
 * of [the messages used by Origin and Destination].
 */
library HeaderLib {
    using ByteString for bytes;
    using TypedMemView for bytes29;

    uint16 internal constant HEADER_VERSION = 1;

    /**
     * @dev Header memory layout
     * [000 .. 002): version            uint16   2 bytes
     * [002 .. 006): origin             uint32   4 bytes
     * [006 .. 038): sender             bytes32 32 bytes
     * [038 .. 042): nonce              uint32   4 bytes
     * [042 .. 046): destination        uint32   4 bytes
     * [046 .. 078): recipient          bytes32 32 bytes
     * [078 .. 082): optimisticSeconds  uint32   4 bytes
     */

    uint256 internal constant OFFSET_VERSION = 0;
    uint256 internal constant OFFSET_ORIGIN = 2;
    uint256 internal constant OFFSET_SENDER = 6;
    uint256 internal constant OFFSET_NONCE = 38;
    uint256 internal constant OFFSET_DESTINATION = 42;
    uint256 internal constant OFFSET_RECIPIENT = 46;
    uint256 internal constant OFFSET_OPTIMISTIC_SECONDS = 78;

    uint256 internal constant HEADER_LENGTH = 82;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              FORMATTERS                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Header payload with provided fields
     * @param _origin               Domain of origin chain
     * @param _sender               Address that sent the message
     * @param _nonce                Message nonce on origin chain
     * @param _destination          Domain of destination chain
     * @param _recipient            Address that will receive the message
     * @param _optimisticSeconds    Optimistic period for message execution
     * @return Formatted header
     **/
    function formatHeader(
        uint32 _origin,
        bytes32 _sender,
        uint32 _nonce,
        uint32 _destination,
        bytes32 _recipient,
        uint32 _optimisticSeconds
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                HEADER_VERSION,
                _origin,
                _sender,
                _nonce,
                _destination,
                _recipient,
                _optimisticSeconds
            );
    }

    /**
     * @notice Returns a Header view over for the given payload.
     * @dev Will revert if the payload is not a header payload.
     */
    function castToHeader(bytes memory _payload) internal pure returns (Header) {
        return castToHeader(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a Header view.
     * @dev Will revert if the memory view is not over a header payload.
     */
    function castToHeader(bytes29 _view) internal pure returns (Header) {
        require(isHeader(_view), "Not a header payload");
        return Header.wrap(_view);
    }

    /**
     * @notice Checks that a payload is a formatted Header.
     */
    function isHeader(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Check if version exists in the payload
        if (length < 2) return false;
        // Check that header version and its length matches
        return _getVersion(_view) == HEADER_VERSION && length == HEADER_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Header _header) internal pure returns (bytes29) {
        return Header.unwrap(_header);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            HEADER SLICING                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns header's version field.
    function version(Header _header) internal pure returns (uint16) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_header);
        return _getVersion(_view);
    }

    /// @notice Returns header's origin field
    function origin(Header _header) internal pure returns (uint32) {
        bytes29 _view = unwrap(_header);
        return uint32(_view.indexUint(OFFSET_ORIGIN, 4));
    }

    /// @notice Returns header's sender field
    function sender(Header _header) internal pure returns (bytes32) {
        bytes29 _view = unwrap(_header);
        return _view.index(OFFSET_SENDER, 32);
    }

    /// @notice Returns header's nonce field
    function nonce(Header _header) internal pure returns (uint32) {
        bytes29 _view = unwrap(_header);
        return uint32(_view.indexUint(OFFSET_NONCE, 4));
    }

    /// @notice Returns header's destination field
    function destination(Header _header) internal pure returns (uint32) {
        bytes29 _view = unwrap(_header);
        return uint32(_view.indexUint(OFFSET_DESTINATION, 4));
    }

    /// @notice Returns header's recipient field as bytes32
    function recipient(Header _header) internal pure returns (bytes32) {
        bytes29 _view = unwrap(_header);
        return _view.index(OFFSET_RECIPIENT, 32);
    }

    /// @notice Returns header's optimistic seconds field
    function optimisticSeconds(Header _header) internal pure returns (uint32) {
        bytes29 _view = unwrap(_header);
        return uint32(_view.indexUint(OFFSET_OPTIMISTIC_SECONDS, 4));
    }

    /// @notice Returns header's recipient field as an address
    function recipientAddress(Header _header) internal pure returns (address) {
        return TypeCasts.bytes32ToAddress(recipient(_header));
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           PRIVATE HELPERS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns a version field without checking if payload is properly formatted.
    function _getVersion(bytes29 _view) internal pure returns (uint16) {
        return uint16(_view.indexUint(OFFSET_VERSION, 2));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Tips is a memory over over a formatted message tips payload.
type Tips is bytes29;
/// @dev Attach library functions to Tips
using {
    TipsLib.unwrap,
    TipsLib.version,
    TipsLib.notaryTip,
    TipsLib.broadcasterTip,
    TipsLib.proverTip,
    TipsLib.executorTip,
    TipsLib.totalTips
} for Tips global;

/**
 * @notice Library for versioned formatting [the tips part]
 * of [the messages used by Origin and Destination].
 */
library TipsLib {
    using ByteString for bytes;
    using TypedMemView for bytes29;

    uint16 internal constant TIPS_VERSION = 1;

    // TODO: determine if we need to pack the tips values,
    // or if using uint256 instead will suffice.

    /**
     * @dev Tips memory layout
     * [000 .. 002): version            uint16	 2 bytes
     * [002 .. 014): notaryTip          uint96	12 bytes
     * [014 .. 026): broadcasterTip     uint96	12 bytes
     * [026 .. 038): proverTip          uint96	12 bytes
     * [038 .. 050): executorTip        uint96	12 bytes
     */

    uint256 internal constant OFFSET_VERSION = 0;
    uint256 internal constant OFFSET_NOTARY = 2;
    uint256 internal constant OFFSET_BROADCASTER = 14;
    uint256 internal constant OFFSET_PROVER = 26;
    uint256 internal constant OFFSET_EXECUTOR = 38;

    uint256 internal constant TIPS_LENGTH = 50;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                 TIPS                                 ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Tips payload with provided fields
     * @param _notaryTip        Tip for the Notary
     * @param _broadcasterTip   Tip for the Broadcaster
     * @param _proverTip        Tip for the Prover
     * @param _executorTip      Tip for the Executor
     * @return Formatted tips
     **/
    function formatTips(
        uint96 _notaryTip,
        uint96 _broadcasterTip,
        uint96 _proverTip,
        uint96 _executorTip
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(TIPS_VERSION, _notaryTip, _broadcasterTip, _proverTip, _executorTip);
    }

    /**
     * @notice Returns a formatted Tips payload specifying empty tips.
     * @return Formatted tips
     **/
    function emptyTips() internal pure returns (bytes memory) {
        return formatTips(0, 0, 0, 0);
    }

    /**
     * @notice Returns a Tips view over for the given payload.
     * @dev Will revert if the payload is not a tips payload.
     */
    function castToTips(bytes memory _payload) internal pure returns (Tips) {
        return castToTips(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a Tips view.
     * @dev Will revert if the memory view is not over a tips payload.
     */
    function castToTips(bytes29 _view) internal pure returns (Tips) {
        require(isTips(_view), "Not a tips payload");
        return Tips.wrap(_view);
    }

    /// @notice Checks that a payload is a formatted Tips payload.
    function isTips(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Check if version exists in the payload
        if (length < OFFSET_NOTARY) return false;
        // Check that tips version and its length matches
        return _getVersion(_view) == TIPS_VERSION && length == TIPS_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Tips _tips) internal pure returns (bytes29) {
        return Tips.unwrap(_tips);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             TIPS SLICING                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns version of formatted tips
    function version(Tips _tips) internal pure returns (uint16) {
        // Get the underlying memory view
        bytes29 _view = _tips.unwrap();
        return _getVersion(_view);
    }

    /// @notice Returns notaryTip field
    function notaryTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_NOTARY, 12));
    }

    /// @notice Returns broadcasterTip field
    function broadcasterTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_BROADCASTER, 12));
    }

    /// @notice Returns proverTip field
    function proverTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_PROVER, 12));
    }

    /// @notice Returns executorTip field
    function executorTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_EXECUTOR, 12));
    }

    /// @notice Returns total tip amount.
    function totalTips(Tips _tips) internal pure returns (uint96) {
        // In practice there's no chance that the total tips value would not fit into uint96.
        // TODO: determine if we want to use uint256 here instead anyway.
        return notaryTip(_tips) + broadcasterTip(_tips) + proverTip(_tips) + executorTip(_tips);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           PRIVATE HELPERS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns a version field without checking if payload is properly formatted.
    function _getVersion(bytes29 _view) private pure returns (uint16) {
        return uint16(_view.indexUint(OFFSET_VERSION, 2));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { ATTESTATION_LENGTH } from "./Constants.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Attestation is a memory view over a formatted attestation payload.
type Attestation is bytes29;
/// @dev Attach library functions to Attestation
using {
    AttestationLib.unwrap,
    AttestationLib.equalToSummit,
    AttestationLib.toDestinationAttestation,
    AttestationLib.hash,
    AttestationLib.root,
    AttestationLib.height,
    AttestationLib.nonce,
    AttestationLib.blockNumber,
    AttestationLib.timestamp
} for Attestation global;

/// @dev Struct representing Attestation, as it is stored in the Summit contract.
struct SummitAttestation {
    bytes32 root;
    uint8 height;
    uint40 blockNumber;
    uint40 timestamp;
}
/// @dev Attach library functions to SummitAttestation
using { AttestationLib.formatSummitAttestation } for SummitAttestation global;

/// @dev Struct representing Attestation, as it is stored in the Destination contract.
/// mapping (bytes32 root => DestinationAttestation) is supposed to be used
struct DestinationAttestation {
    address notary;
    uint8 height;
    uint32 nonce;
    uint40 destTimestamp;
    // 16 bits left for tight packing
}
/// @dev Attach library functions to DestinationAttestation
using { AttestationLib.isEmpty } for DestinationAttestation global;

library AttestationLib {
    using ByteString for bytes;
    using TypedMemView for bytes29;

    /**
     * @dev Attestation structure represents the "Snapshot Merkle Tree" created from
     * every Notary snapshot accepted by the Summit contract. Attestation includes
     * the root and height of "Snapshot Merkle Tree", as well as additional metadata.
     *
     * Steps for creation of "Snapshot Merkle Tree":
     * 1. The list of hashes is composed for states in the Notary snapshot.
     * 2. The list is padded with zero values until its length is a power of two.
     * 3. Values from the lists are used as leafs and the merkle tree is constructed.
     *
     * Similar to Origin, every derived Notary's "Snapshot Merkle Root" is saved in Summit contract.
     * The main difference is that Origin contract itself is keeping track of an incremental merkle tree,
     * by inserting the hash of the dispatched message and calculating the new "Origin Merkle Root".
     * While Summit relies on Guards and Notaries to provide snapshot data, which is used to calculate the
     * "Snapshot Merkle Root".
     *
     * Origin's State is "state of Origin Merkle Tree after N-th message was dispatched".
     * Summit's Attestation is "data for the N-th accepted Notary Snapshot".
     *
     * Attestation is considered "valid" in Summit contract, if it matches the N-th (nonce)
     * snapshot submitted by Notaries.
     * Attestation is considered "valid" in Origin contract, if its underlying Snapshot is "valid".
     *
     * This means that a snapshot could be "valid" in Summit contract and "invalid" in Origin, if the underlying
     * snapshot is invalid (i.e. one of the states in the list is invalid).
     * The opposite could also be true. If a perfectly valid snapshot was never submitted to Summit, its attestation
     * would be valid in Origin, but invalid in Summit (it was never accepted, so the metadata would be incorrect).
     *
     * Attestation is considered "globally valid", if it is valid in the Summit and all the Origin contracts.
     *
     * @dev Memory layout of Attestation fields
     * [000 .. 032): root           bytes32 32 bytes    Root for "Snapshot Merkle Tree" created from a Notary snapshot
     * [032 .. 033): height         uint8    1 byte     Height of "Snapshot Merkle Tree" created from a Notary snapshot
     * [033 .. 037): nonce          uint32   4 bytes    Total amount of all accepted Notary snapshots
     * [037 .. 042): blockNumber    uint40   5 bytes    Block when this Notary snapshot was accepted in Summit
     * [042 .. 047): timestamp      uint40   5 bytes    Time when this Notary snapshot was accepted in Summit
     *
     * The variables below are not supposed to be used outside of the library directly.
     */

    uint256 private constant OFFSET_ROOT = 0;
    uint256 private constant OFFSET_DEPTH = 32;
    uint256 private constant OFFSET_NONCE = 33;
    uint256 private constant OFFSET_BLOCK_NUMBER = 37;
    uint256 private constant OFFSET_TIMESTAMP = 42;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             ATTESTATION                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Attestation payload with provided fields.
     * @param _root         Snapshot merkle tree's root
     * @param _height       Snapshot merkle tree's height
     * @param _nonce        Attestation Nonce
     * @param _blockNumber  Block number when attestation was created in Summit
     * @param _timestamp    Block timestamp when attestation was created in Summit
     * @return Formatted attestation
     **/
    function formatAttestation(
        bytes32 _root,
        uint8 _height,
        uint32 _nonce,
        uint40 _blockNumber,
        uint40 _timestamp
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_root, _height, _nonce, _blockNumber, _timestamp);
    }

    /**
     * @notice Returns an Attestation view over the given payload.
     * @dev Will revert if the payload is not an attestation.
     */
    function castToAttestation(bytes memory _payload) internal pure returns (Attestation) {
        return castToAttestation(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to an Attestation view.
     * @dev Will revert if the memory view is not over an attestation.
     */
    function castToAttestation(bytes29 _view) internal pure returns (Attestation) {
        require(isAttestation(_view), "Not an attestation");
        return Attestation.wrap(_view);
    }

    /// @notice Checks that a payload is a formatted Attestation.
    function isAttestation(bytes29 _view) internal pure returns (bool) {
        return _view.len() == ATTESTATION_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Attestation _att) internal pure returns (bytes29) {
        return Attestation.unwrap(_att);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          SUMMIT ATTESTATION                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Attestation payload with provided fields.
     * @param _summitAtt    Attestation struct as it stored in Summit contract
     * @param _nonce        Attestation nonce
     * @return Formatted attestation
     */
    function formatSummitAttestation(SummitAttestation memory _summitAtt, uint32 _nonce)
        internal
        pure
        returns (bytes memory)
    {
        return
            formatAttestation({
                _root: _summitAtt.root,
                _height: _summitAtt.height,
                _nonce: _nonce,
                _blockNumber: _summitAtt.blockNumber,
                _timestamp: _summitAtt.timestamp
            });
    }

    /// @notice Checks that an Attestation and its Summit representation are equal.
    function equalToSummit(Attestation _att, SummitAttestation memory _summitAtt)
        internal
        pure
        returns (bool)
    {
        return
            _att.root() == _summitAtt.root &&
            _att.height() == _summitAtt.height &&
            _att.blockNumber() == _summitAtt.blockNumber &&
            _att.timestamp() == _summitAtt.timestamp;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                       DESTINATION ATTESTATION                        ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function toDestinationAttestation(Attestation _att, address _notary)
        internal
        view
        returns (DestinationAttestation memory attestation)
    {
        attestation.notary = _notary;
        attestation.height = _att.height();
        attestation.nonce = _att.nonce();
        // We need to store the timestamp when attestation was submitted to Destination
        attestation.destTimestamp = uint40(block.timestamp);
    }

    function isEmpty(DestinationAttestation memory _destAtt) internal pure returns (bool) {
        return _destAtt.notary == address(0);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                         ATTESTATION HASHING                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns the hash of an Attestation, that could be later signed by a Notary.
    function hash(Attestation _att) internal pure returns (bytes32) {
        // Get the underlying memory view
        bytes29 _view = _att.unwrap();
        // TODO: include Attestation-unique salt in the hash
        return _view.keccak();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                         ATTESTATION SLICING                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns root of the Snapshot merkle tree created in the Summit contract.
    function root(Attestation _att) internal pure returns (bytes32) {
        bytes29 _view = _att.unwrap();
        return _view.index({ _index: OFFSET_ROOT, _bytes: 32 });
    }

    /// @notice Returns height of the Snapshot merkle tree created in the Summit contract.
    function height(Attestation _att) internal pure returns (uint8) {
        bytes29 _view = _att.unwrap();
        return uint8(_view.indexUint({ _index: OFFSET_DEPTH, _bytes: 1 }));
    }

    /// @notice Returns nonce of Summit contract at the time, when attestation was created.
    function nonce(Attestation _att) internal pure returns (uint32) {
        bytes29 _view = _att.unwrap();
        return uint32(_view.indexUint({ _index: OFFSET_NONCE, _bytes: 4 }));
    }

    /// @notice Returns a block number when attestation was created in Summit.
    function blockNumber(Attestation _att) internal pure returns (uint40) {
        bytes29 _view = _att.unwrap();
        return uint40(_view.indexUint({ _index: OFFSET_BLOCK_NUMBER, _bytes: 5 }));
    }

    /// @notice Returns a block timestamp when attestation was created in Summit.
    /// @dev This is the timestamp according to the Synapse Chain.
    function timestamp(Attestation _att) internal pure returns (uint40) {
        bytes29 _view = _att.unwrap();
        return uint40(_view.indexUint({ _index: OFFSET_TIMESTAMP, _bytes: 5 }));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { DestinationAttestation } from "../libs/Attestation.sol";

interface IAttestationHub {
    /**
     * @notice Returns the total amount of Notaries attestations that have been accepted.
     */
    function attestationsAmount() external view returns (uint256);

    /**
     * @notice Returns an attestation from the list of all accepted Notary attestations.
     * @dev Index refers to attestation's snapshot root position in `roots` array.
     * @param _index   Attestation index
     * @return root    Snapshot root for the attestation
     * @return destAtt Rest of attestation data that Destination keeps track of
     */
    function getAttestation(uint256 _index)
        external
        view
        returns (bytes32 root, DestinationAttestation memory destAtt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SummitAttestation } from "./Attestation.sol";
import { ByteString } from "./ByteString.sol";
import { SNAPSHOT_MAX_STATES, STATE_LENGTH } from "./Constants.sol";
import { MerkleList } from "./MerkleList.sol";
import { State, StateLib } from "./State.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Snapshot is a memory view over a formatted snapshot payload: a list of states.
type Snapshot is bytes29;
/// @dev Attach library functions to Snapshot
using {
    SnapshotLib.unwrap,
    SnapshotLib.hash,
    SnapshotLib.state,
    SnapshotLib.statesAmount,
    SnapshotLib.height,
    SnapshotLib.root,
    SnapshotLib.toSummitAttestation
} for Snapshot global;

/// @dev Struct representing Snapshot, as it is stored in the Summit contract.
/// Summit contract is supposed to store states. Snapshot is a list of states,
/// so we are storing a list of references to already stored states.
struct SummitSnapshot {
    // TODO: compress this - indexes might as well be uint32/uint64
    uint256[] statePtrs;
}
/// @dev Attach library functions to SummitSnapshot
using { SnapshotLib.getStatesAmount, SnapshotLib.getStatePtr } for SummitSnapshot global;

library SnapshotLib {
    using ByteString for bytes;
    using StateLib for bytes29;
    using TypedMemView for bytes29;

    /**
     * @dev Snapshot structure represents the state of multiple Origin contracts deployed on multiple chains.
     * In short, snapshot is a list of "State" structs. See State.sol for details about the "State" structs.
     *
     * Snapshot is considered "valid" in Origin, if every state referring to that Origin is valid there.
     * Snapshot is considered "globally valid", if it is "valid" in every Origin contract.
     *
     * Both Guards and Notaries are supposed to form snapshots and sign snapshot.hash() to verify its validity.
     * Each Guard should be monitoring a set of Origin contracts chosen as they see fit. They are expected
     * to form snapshots with Origin states for this set of chains, sign and submit them to Summit contract.
     *
     * Notaries are expected to monitor the Summit contract for new snapshots submitted by the Guards.
     * They should be forming their own snapshots using states from snapshots of any of the Guards.
     * The states for the Notary snapshots don't have to come from the same Guard snapshot,
     * or don't even have to be submitted by the same Guard.
     *
     * With their signature, Notary effectively "notarizes" the work that some Guards have done in Summit contract.
     * Notary signature on a snapshot doesn't only verify the validity of the Origins, but also serves as
     * a proof of liveliness for Guards monitoring these Origins.
     *
     * @dev Snapshot memory layout
     * [000 .. 050) states[0]   bytes   50 bytes
     * [050 .. 100) states[1]   bytes   50 bytes
     *      ..
     * [AAA .. BBB) states[N-1] bytes   50 bytes
     */

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               SNAPSHOT                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Snapshot payload using a list of States.
     * @param _states   Arrays of State-typed memory views over Origin states
     * @return Formatted snapshot
     */
    function formatSnapshot(State[] memory _states) internal view returns (bytes memory) {
        require(_isValidAmount(_states.length), "Invalid states amount");
        // First we unwrap State-typed views into generic views
        uint256 length = _states.length;
        bytes29[] memory views = new bytes29[](length);
        for (uint256 i = 0; i < length; ++i) {
            views[i] = _states[i].unwrap();
        }
        // Finally, we join them in a single payload. This avoids doing unnecessary copies in the process.
        return TypedMemView.join(views);
    }

    /**
     * @notice Returns a Snapshot view over for the given payload.
     * @dev Will revert if the payload is not a snapshot payload.
     */
    function castToSnapshot(bytes memory _payload) internal pure returns (Snapshot) {
        return castToSnapshot(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a Snapshot view.
     * @dev Will revert if the memory view is not over a snapshot payload.
     */
    function castToSnapshot(bytes29 _view) internal pure returns (Snapshot) {
        require(isSnapshot(_view), "Not a snapshot");
        return Snapshot.wrap(_view);
    }

    /**
     * @notice Checks that a payload is a formatted Snapshot.
     */
    function isSnapshot(bytes29 _view) internal pure returns (bool) {
        // Snapshot needs to have exactly N * STATE_LENGTH bytes length
        // N needs to be in [1 .. SNAPSHOT_MAX_STATES] range
        uint256 length = _view.len();
        uint256 _statesAmount = length / STATE_LENGTH;
        return _statesAmount * STATE_LENGTH == length && _isValidAmount(_statesAmount);
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Snapshot _snapshot) internal pure returns (bytes29) {
        return Snapshot.unwrap(_snapshot);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           SUMMIT SNAPSHOT                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function toSummitSnapshot(uint256[] memory _statePtrs)
        internal
        pure
        returns (SummitSnapshot memory snapshot)
    {
        snapshot.statePtrs = _statePtrs;
    }

    function getStatesAmount(SummitSnapshot memory _snapshot) internal pure returns (uint256) {
        return _snapshot.statePtrs.length;
    }

    function getStatePtr(SummitSnapshot memory _snapshot, uint256 _index)
        internal
        pure
        returns (uint256)
    {
        require(_index < getStatesAmount(_snapshot), "Out of range");
        return _snapshot.statePtrs[_index];
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           SNAPSHOT HASHING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns the hash of a Snapshot, that could be later signed by an Agent.
    function hash(Snapshot _snapshot) internal pure returns (bytes32 hashedSnapshot) {
        // Get the underlying memory view
        bytes29 _view = _snapshot.unwrap();
        // TODO: include Snapshot-unique salt in the hash
        return _view.keccak();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           SNAPSHOT SLICING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns a state with a given index from the snapshot.
    function state(Snapshot _snapshot, uint256 _stateIndex) internal pure returns (State) {
        bytes29 _view = _snapshot.unwrap();
        uint256 indexFrom = _stateIndex * STATE_LENGTH;
        require(indexFrom < _view.len(), "Out of range");
        return _view.slice({ _index: indexFrom, _len: STATE_LENGTH, newType: 0 }).castToState();
    }

    /// @notice Returns the amount of states in the snapshot.
    function statesAmount(Snapshot _snapshot) internal pure returns (uint256) {
        bytes29 _view = _snapshot.unwrap();
        return _view.len() / STATE_LENGTH;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            SNAPSHOT ROOT                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns the height of the extended "Snapshot Merkle Tree":
    /// every "state leaf" is in fact a node with two sub-leafs.
    /// @dev snapshot.height() is the length of the "extended merkle proof" for (root, origin) leaf:
    /// keccak256(metadata) is the first item in the "extended proof" list,
    /// followed by the remainder of the "merkle proof" from the "Snapshot Merkle Tree"
    function height(Snapshot _snapshot) internal pure returns (uint8 treeHeight) {
        // Account for the fact that every "state leaf" is a node with two sub-leafs
        treeHeight = 1;
        uint256 _statesAmount = _snapshot.statesAmount();
        for (uint256 amount = 1; amount < _statesAmount; amount <<= 1) {
            ++treeHeight;
        }
    }

    /// @notice Returns the root for the "Snapshot Merkle Tree" composed of state leafs from the snapshot.
    function root(Snapshot _snapshot) internal pure returns (bytes32) {
        uint256 _statesAmount = _snapshot.statesAmount();
        bytes32[] memory hashes = new bytes32[](_statesAmount);
        for (uint256 i = 0; i < _statesAmount; ++i) {
            // Each State has two sub-leafs, their hash is used as "leaf" in "Snapshot Merkle Tree"
            hashes[i] = _snapshot.state(i).hash();
        }
        MerkleList.calculateRoot(hashes);
        // hashes[0] now stores the value for the Merkle Root of the list
        return hashes[0];
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          SUMMIT ATTESTATION                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns an Attestation struct to save in the Summit contract.
    /// Current block number and timestamp are used.
    function toSummitAttestation(Snapshot _snapshot)
        internal
        view
        returns (SummitAttestation memory attestation)
    {
        attestation.root = _snapshot.root();
        attestation.height = _snapshot.height();
        attestation.blockNumber = uint40(block.number);
        attestation.timestamp = uint40(block.timestamp);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          PRIVATE FUNCTIONS                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Checks if snapshot's states amount is valid.
    function _isValidAmount(uint256 _statesAmount) internal pure returns (bool) {
        // Need to have at least one state in a snapshot.
        // Also need to have no more than `SNAPSHOT_MAX_STATES` states in a snapshot.
        return _statesAmount > 0 && _statesAmount <= SNAPSHOT_MAX_STATES;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { AgentSet } from "../libs/AgentSet.sol";
import { Auth } from "../libs/Auth.sol";
import { Signature } from "../libs/ByteString.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { AgentRegistryEvents } from "../events/AgentRegistryEvents.sol";
import { IAgentRegistry } from "../interfaces/IAgentRegistry.sol";
// ═════════════════════════════ EXTERNAL IMPORTS ══════════════════════════════
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice Registry used for verifying signatures of any of the Agents.
 * Both Guards and Notaries could be stored in a single AgentRegistry.
 * An option to ignore certain agents is available, see {_isIgnoredAgent}.
 * @dev Following assumptions are implied:
 * 1. Guard is active on all domains at once.
 * 2. Notary is active on a single domain.
 * 3. Same account can't be both a Guard and a Notary.
 */
abstract contract AgentRegistry is AgentRegistryEvents, IAgentRegistry {
    using AgentSet for AgentSet.DomainAddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               STORAGE                                ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Refers to the current epoch. Whenever a full agent reset is required
     * by BondingManager, a new epoch starts. This saves us from iterating over all
     * agents and deleting them, which could be gas consuming.
     * @dev Variable is private as the child contracts are not supposed to modify it.
     * Use _currentEpoch() getter if needed.
     */
    uint256 private epoch;

    /**
     * @notice All active domains, i.e. domains having at least one active Notary.
     * Note: guards are stored with domain = 0, but we don't want to mix
     * "domains with at least one active Notary" and "zero domain with at least one active Guard",
     * so we are NOT storing domain == 0 in this set.
     */
    // (epoch => [domains with at least one active Notary])
    mapping(uint256 => EnumerableSet.UintSet) internal domains;

    /**
     * @notice DomainAddressSet implies that every agent is stored as a (domain, account) tuple.
     * Guard is active on all domains => Guards are stored as (domain = 0, account).
     * Notary is active on one (non-zero) domain => Notaries are stored as (domain > 0, account).
     */
    // (epoch => [set of active agents for all domains])
    mapping(uint256 => AgentSet.DomainAddressSet) internal agents;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              MODIFIERS                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Ensures that there is at least one active Notary for the given domain.
     */
    modifier haveActiveNotary(uint32 _domain) {
        require(_isActiveDomain(_domain), "No active notaries");
        _;
    }

    /**
     * @notice Ensures that there is at least one active Guard.
     */
    modifier haveActiveGuard() {
        // Guards are stored with `_domain == 0`
        require(amountAgents({ _domain: 0 }) != 0, "No active guards");
        _;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            EXTERNAL VIEWS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @inheritdoc IAgentRegistry
    function allAgents(uint32 _domain) external view returns (address[] memory) {
        return agents[_currentEpoch()].values(_domain);
    }

    /// @inheritdoc IAgentRegistry
    function allDomains() external view returns (uint32[] memory domains_) {
        uint256[] memory values = domains[_currentEpoch()].values();
        // Use assembly to perform uint256 -> uint32 downcast
        // See OZ's EnumerableSet.values()
        // solhint-disable-next-line no-inline-assembly
        assembly {
            domains_ := values
        }
    }

    /// @inheritdoc IAgentRegistry
    function isActiveAgent(address _account) external view returns (bool isActive, uint32 domain) {
        return _isActiveAgent(_account);
    }

    /// @inheritdoc IAgentRegistry
    function isActiveAgent(uint32 _domain, address _account) external view returns (bool) {
        return _isActiveAgent(_domain, _account);
    }

    /// @inheritdoc IAgentRegistry
    function isActiveDomain(uint32 _domain) external view returns (bool) {
        return _isActiveDomain(_domain);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             PUBLIC VIEWS                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @inheritdoc IAgentRegistry
    function amountAgents(uint32 _domain) public view returns (uint256) {
        return agents[_currentEpoch()].length(_domain);
    }

    /// @inheritdoc IAgentRegistry
    function amountDomains() public view returns (uint256) {
        return domains[_currentEpoch()].length();
    }

    /// @inheritdoc IAgentRegistry
    function getAgent(uint32 _domain, uint256 _agentIndex) public view returns (address) {
        return agents[_currentEpoch()].at(_domain, _agentIndex);
    }

    /// @inheritdoc IAgentRegistry
    function getDomain(uint256 _domainIndex) public view returns (uint32) {
        return uint32(domains[_currentEpoch()].at(_domainIndex));
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          INTERNAL FUNCTIONS                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @dev Tries to add an agent to the domain. If added, emits a corresponding event,
     * updates the list of active domains if necessary, and triggers a corresponding hook.
     * Note: use _domain == 0 to add a Guard, _domain > 0 to add a Notary.
     */
    function _addAgent(uint32 _domain, address _account) internal returns (bool wasAdded) {
        // Some Registries may want to ignore certain agents
        if (_isIgnoredAgent(_domain, _account)) return false;
        // Do the storage read just once
        uint256 _epoch = _currentEpoch();
        // Add to the list of agents for the domain in the current epoch
        wasAdded = agents[_epoch].add(_domain, _account);
        if (wasAdded) {
            emit AgentAdded(_domain, _account);
            // Consider adding domain to the list of "active domains" only if a Notary was added
            if (_domain != 0) {
                // We can skip the "already exists" check here, as EnumerableSet.add() does that
                if (domains[_epoch].add(_domain)) {
                    // Emit the event if domain was added to the list of active domains
                    emit DomainActivated(_domain);
                }
            }
            // Trigger the hook after the work is done
            _afterAgentAdded(_domain, _account);
        }
    }

    /**
     * @dev Tries to remove an agent from the domain. If removed, emits a corresponding event,
     * updates the list of active domains if necessary, and triggers a corresponding hook.
     * Note: use _domain == 0 to remove a Guard, _domain > 0 to remove a Notary.
     */
    function _removeAgent(uint32 _domain, address _account) internal returns (bool wasRemoved) {
        // Some Registries may want to ignore certain agents
        if (_isIgnoredAgent(_domain, _account)) return false;
        // Do the storage read just once
        uint256 _epoch = _currentEpoch();
        // Remove from the list of agents for the domain in the current epoch
        wasRemoved = agents[_epoch].remove(_domain, _account);
        if (wasRemoved) {
            emit AgentRemoved(_domain, _account);
            // Consider removing domain to the list of "active domains" only if a Notary was removed
            if (_domain != 0 && amountAgents(_domain) == 0) {
                // Remove domain for the "active list", if that was the last agent
                domains[_epoch].remove(_domain);
                emit DomainDeactivated(_domain);
            }
            // Trigger the hook after the work is done
            _afterAgentRemoved(_domain, _account);
        }
    }

    /**
     * @dev Tries to slash an agent active on the domain by removing it.
     * If slashed, emits a corresponding event, and triggers a corresponding hook if verified locally.
     * Hook will not be triggered, if agent was slashed elsewhere.
     * Note: use _domain == 0 to slash a Guard, _domain > 0 to slash a Notary.
     */
    function _slashAgent(
        uint32 _domain,
        address _account,
        bool _verified
    ) internal returns (bool wasSlashed) {
        wasSlashed = _removeAgent(_domain, _account);
        if (wasSlashed) {
            emit AgentSlashed(_domain, _account);
            if (_verified) _afterAgentSlashed(_domain, _account);
        }
    }

    /**
     * @dev Removes all active agents from all domains.
     * Note: iterating manually over all agents in order to delete them all is super inefficient.
     * Deleting sets (which contain mappings inside) is literally not possible.
     * So we're switching to fresh sets instead.
     */
    function _resetAgents() internal {
        ++epoch;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                HOOKS                                 ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    // solhint-disable no-empty-blocks

    /// @dev Hook that is always called after a new agent was added for the domain.
    function _afterAgentAdded(uint32 _domain, address _account) internal virtual {}

    /// @dev Hook that is always called after an existing agent was removed from the domain.
    function _afterAgentRemoved(uint32 _domain, address _account) internal virtual {}

    /// @dev Hook that is called after an existing agent was slashed,
    /// when verification of an invalid agent statement was done in this contract.
    function _afterAgentSlashed(uint32 _domain, address _account) internal virtual {}

    // solhint-enable no-empty-blocks

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                            INTERNAL VIEWS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @dev Returns current epoch, i.e. an index that is used to determine the currently
     * used sets for active agents and domains.
     */
    function _currentEpoch() internal view returns (uint256) {
        return epoch;
    }

    /**
     * @dev Recovers a signer from digest and signature, and checks if they are
     * active on the given domain.
     * Note: domain == 0 refers to a Guard, while _domain > 0 refers to a Notary.
     */
    function _checkAgentAuth(
        uint32 _domain,
        bytes32 _digest,
        Signature _signature
    ) internal view returns (address agent) {
        agent = Auth.recoverSigner(_digest, _signature);
        require(_isActiveAgent(_domain, agent), "Signer is not authorized");
    }

    /**
     * @dev Checks if agent is active on any of the domains.
     * Note: this returns if agent is active, and the domain where they're active.
     */
    function _isActiveAgent(address _account) internal view returns (bool, uint32) {
        // Check the list of global agents in the current epoch
        return agents[_currentEpoch()].contains(_account);
    }

    /**
     * @dev Checks if agent is active on the given domain.
     * Note: domain == 0 refers to a Guard, while _domain > 0 refers to a Notary.
     */
    function _isActiveAgent(uint32 _domain, address _account) internal view returns (bool) {
        // Check the list of the domain's agents in the current epoch
        return agents[_currentEpoch()].contains(_domain, _account);
    }

    /**
     * @dev Checks if there is at least one active Notary for the given domain.
     * Note: will return false for `_domain == 0`, even if there are active Guards.
     */
    function _isActiveDomain(uint32 _domain) internal view returns (bool) {
        return domains[_currentEpoch()].contains(_domain);
    }

    /**
     * @dev Child contracts should override this function to prevent
     * certain agents from being added and removed.
     * For instance, Origin might want to ignore all agents from the local domain.
     * Note: It is assumed that no agent can change its "ignored" status in any AgentRegistry.
     * In other words, do not use any values that might change over time, when implementing.
     * Otherwise, unexpected behavior might be expected. For instance, if an agent was added,
     * and then it became "ignored", it would be not possible to remove such agent.
     * Note: domain == 0 refers to a Guard, while _domain > 0 refers to a Notary.
     */
    function _isIgnoredAgent(uint32 _domain, address _account) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Versioned
 * @notice Version getter for contracts. Doesn't use any storage slots, meaning
 * it will never cause any troubles with the upgradeable contracts. For instance, this contract
 * can be added or removed from the inheritance chain without shifting the storage layout.
 **/
abstract contract Versioned {
    /**
     * @notice Struct that is mimicking the storage layout of a string with 32 bytes or less.
     * Length is limited by 32, so the whole string payload takes two memory words:
     * @param length    String length
     * @param data      String characters
     */
    struct _ShortString {
        uint256 length;
        bytes32 data;
    }

    /// @dev Length of the "version string"
    uint256 private immutable _length;
    /// @dev Bytes representation of the "version string".
    /// Strings with length over 32 are not supported!
    bytes32 private immutable _data;

    constructor(string memory _version) {
        _length = bytes(_version).length;
        require(_length <= 32, "String length over 32");
        // bytes32 is left-aligned => this will store the byte representation of the string
        // with the trailing zeroes to complete the 32-byte word
        _data = bytes32(bytes(_version));
    }

    function version() external view returns (string memory versionString) {
        // Load the immutable values to form the version string
        _ShortString memory str = _ShortString(_length, _data);
        // The only way to do this cast is doing some dirty assembly
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            versionString := str
        }
    }
}

abstract contract Version0_0_2 is Versioned {
    // solhint-disable-next-line no-empty-blocks
    constructor() Versioned("0.0.2") {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Here we define common enums and structures to enable their easier reusing later.

/// @dev Potential senders/recipients of a system message
enum SystemEntity {
    Origin,
    Destination,
    BondingManager
}

/**
 * @notice Unified struct for off-chain agent storing
 * @dev Both Guards and Notaries are stored this way.
 * `domain == 0` refers to Guards, who are active on every domain
 * `domain != 0` refers to Notaries, who are active on a single domain
 * @param bonded    Whether agent bonded or unbonded
 * @param domain    Domain, where agent is active
 * @param account   Off-chain agent address
 */
struct AgentInfo {
    // TODO: This won't be needed when Agents Merkle Tree is implemented
    uint32 domain;
    address account;
    bool bonded;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { AgentInfo, SystemEntity } from "../libs/Structures.sol";
// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { DomainContext } from "../context/DomainContext.sol";
import { ISystemContract } from "../interfaces/ISystemContract.sol";
import { InterfaceSystemRouter } from "../interfaces/InterfaceSystemRouter.sol";
// ═════════════════════════════ EXTERNAL IMPORTS ══════════════════════════════
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @notice Shared utilities between Synapse System Contracts: Origin, Destination, etc.
 */
abstract contract SystemContract is DomainContext, OwnableUpgradeable, ISystemContract {
    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              CONSTANTS                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    // domain of the Synapse Chain
    // For Testnet this is chainId of SynChain devnet
    // TODO: replace the placeholder with actual value
    uint32 public constant SYNAPSE_DOMAIN = 901;

    uint256 internal constant ORIGIN = 1 << uint8(SystemEntity.Origin);
    uint256 internal constant DESTINATION = 1 << uint8(SystemEntity.Destination);
    uint256 internal constant BONDING_MANAGER = 1 << uint8(SystemEntity.BondingManager);

    // TODO: reevaluate optimistic period for staking/unstaking bonds
    uint32 internal constant BONDING_OPTIMISTIC_PERIOD = 1 days;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               STORAGE                                ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    InterfaceSystemRouter public systemRouter;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              MODIFIERS                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * System Contracts on all chains (either local or remote).
     * Note: any function protected by this modifier should have last three params:
     * - uint32 _callOrigin
     * - SystemEntity _systemCaller
     * - uint256 _rootSubmittedAt
     * Make sure to check domain/caller, if a function should be only called
     * from a given domain / by a given caller.
     * Make sure to check that a needed amount of time has passed since
     * root submission for the cross-chain calls.
     */
    modifier onlySystemRouter() {
        _assertSystemRouter();
        _;
    }

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * System Contracts on Synapse chain.
     * Note: has to be used alongside with `onlySystemRouter`
     * See `onlySystemRouter` for details about the functions protected by such modifiers.
     */
    modifier onlySynapseChain(uint32 _callOrigin) {
        _assertSynapseChain(_callOrigin);
        _;
    }

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * a set of System Contracts on any chain.
     * Note: has to be used alongside with `onlySystemRouter`
     * See `onlySystemRouter` for details about the functions protected by such modifiers.
     * Note: check constants section for existing mask constants
     * E.g. to restrict the set of callers to three allowed system callers:
     *  onlyCallers(MASK_0 | MASK_1 | MASK_2, _systemCaller)
     */
    modifier onlyCallers(uint256 _allowedMask, SystemEntity _systemCaller) {
        _assertEntityAllowed(_allowedMask, _systemCaller);
        _;
    }

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * BondingManager on their local chain.
     * Note: has to be used alongside with `onlySystemRouter`
     * See `onlySystemRouter` for details about the functions protected by such modifiers.
     */
    modifier onlyLocalBondingManager(uint32 _callOrigin, SystemEntity _caller) {
        _assertLocalDomain(_callOrigin);
        _assertEntityAllowed(BONDING_MANAGER, _caller);
        _;
    }

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * BondingManager on Synapse Chain.
     * Note: has to be used alongside with `onlySystemRouter`
     * See `onlySystemRouter` for details about the functions protected by such modifiers.
     */
    modifier onlySynapseChainBondingManager(uint32 _callOrigin, SystemEntity _systemCaller) {
        _assertSynapseChain(_callOrigin);
        _assertEntityAllowed(BONDING_MANAGER, _systemCaller);
        _;
    }

    /**
     * @dev Modifier for functions that are supposed to be called only from
     * System Contracts on remote chain with a defined minimum optimistic period.
     * Note: has to be used alongside with `onlySystemRouter`
     * See `onlySystemRouter` for details about the functions protected by such modifiers.
     * Note: message could be sent with a period lower than that, but will be executed
     * only when `_optimisticSeconds` have passed.
     * Note: _optimisticSeconds=0 will allow calls from a local chain as well
     */
    modifier onlyOptimisticPeriodOver(uint256 _rootSubmittedAt, uint256 _optimisticSeconds) {
        _assertOptimisticPeriodOver(_rootSubmittedAt, _optimisticSeconds);
        _;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             INITIALIZER                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    // solhint-disable-next-line func-name-mixedcase
    function __SystemContract_initialize() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              OWNER ONLY                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    // solhint-disable-next-line ordering
    function setSystemRouter(InterfaceSystemRouter _systemRouter) external onlyOwner {
        systemRouter = _systemRouter;
    }

    /**
     * @dev Should be impossible to renounce ownership;
     * we override OpenZeppelin OwnableUpgradeable's
     * implementation of renounceOwnership to make it a no-op
     */
    function renounceOwnership() public override onlyOwner {} //solhint-disable-line no-empty-blocks

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                        SYSTEM CALL SHORTCUTS                         ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Perform a System Call to a BondingManager on a given domain
    /// with the given optimistic period and data.
    function _callBondingManager(
        uint32 _domain,
        uint32 _optimisticSeconds,
        bytes memory _data
    ) internal {
        systemRouter.systemCall({
            _destination: _domain,
            _optimisticSeconds: _optimisticSeconds,
            _recipient: SystemEntity.BondingManager,
            _data: _data
        });
    }

    /// @dev Perform a System Call to a local BondingManager with the given `_data`.
    function _callLocalBondingManager(bytes memory _data) internal {
        _callBondingManager(localDomain, 0, _data);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                 INTERNAL VIEWS: SECURITY ASSERTIONS                  ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function _onSynapseChain() internal view returns (bool) {
        return localDomain == SYNAPSE_DOMAIN;
    }

    function _assertSystemRouter() internal view {
        require(msg.sender == address(systemRouter), "!systemRouter");
    }

    function _assertOptimisticPeriodOver(uint256 _rootSubmittedAt, uint256 _optimisticSeconds)
        internal
        view
    {
        require(block.timestamp >= _rootSubmittedAt + _optimisticSeconds, "!optimisticPeriod");
    }

    function _assertEntityAllowed(uint256 _allowedMask, SystemEntity _caller) internal pure {
        require(_entityAllowed(_allowedMask, _caller), "!allowedCaller");
    }

    function _assertSynapseChain(uint32 _domain) internal pure {
        require(_domain == SYNAPSE_DOMAIN, "!synapseDomain");
    }

    /**
     * @notice Checks if a given entity is allowed to call a function using a _systemMask
     * @param _systemMask a mask of allowed entities
     * @param _entity a system entity to check
     * @return true if _entity is allowed to call a function
     *
     * @dev this function works by converting the enum value to a non-zero bit mask
     * we then use a bitwise AND operation to check if permission bits allow the entity
     * to perform this operation, more details can be found here:
     * https://en.wikipedia.org/wiki/Bitwise_operation#AND
     */
    function _entityAllowed(uint256 _systemMask, SystemEntity _entity)
        internal
        pure
        returns (bool)
    {
        return _systemMask & _getSystemMask(_entity) != 0;
    }

    /**
     * @notice Returns a mask for a given system entity
     * @param _entity System entity
     * @return a non-zero mask for a given system entity
     *
     * Converts an enum value into a non-zero bit mask used for a bitwise AND check
     * E.g. for Origin (0) returns 1, for Destination (1) returns 2
     */
    function _getSystemMask(SystemEntity _entity) internal pure returns (uint256) {
        return 1 << uint8(_entity);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                      INTERNAL VIEWS: AGENT DATA                      ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @dev Convenience shortcut for creating data for the slashAgent system call.
    function _dataSlashAgent(uint32 _domain, address _agent) internal pure returns (bytes memory) {
        return _dataSlashAgent(AgentInfo(_domain, _agent, false));
    }

    /**
     * @notice Constructs data for the system call to slash a given agent.
     */
    function _dataSlashAgent(AgentInfo memory _info) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                ISystemContract.slashAgent.selector,
                0, // rootSubmittedAt
                0, // callOrigin
                0, // systemCaller
                _info
            );
    }

    /// @dev Constructs data for the system call to sync the given agent.
    function _dataSyncAgent(AgentInfo memory _info) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                ISystemContract.syncAgent.selector,
                0, // rootSubmittedAt
                0, // callOrigin
                0, // systemCaller
                _info
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SystemEntity } from "../libs/Structures.sol";

interface InterfaceSystemRouter {
    /**
     * @notice Call a System Contract on the destination chain with a given data payload.
     * Note: for system calls on the local chain
     * - use `destination = localDomain`
     * - `_optimisticSeconds` value will be ignored
     *
     * @dev Only System contracts are allowed to call this function.
     * Note: knowledge of recipient address is not required, routing will be done by SystemRouter
     * on the destination chain. Following call will be made on destination chain:
     * - recipient.call(_data, callOrigin, systemCaller, rootSubmittedAt)
     * This allows recipient to check:
     * - callOrigin: domain where a system call originated (local domain in this case)
     * - systemCaller: system entity who initiated the call (msg.sender on local chain)
     * - rootSubmittedAt:
     *   - For cross-chain calls: timestamp when merkle root (used for executing the system call)
     *     was submitted to destination and its optimistic timer started ticking
     *   - For on-chain calls: timestamp of the current block
     *
     * @param _destination          Domain of destination chain
     * @param _optimisticSeconds    Optimistic period for the message
     * @param _recipient            System entity to receive the call on destination chain
     * @param _data                 Data for calling recipient on destination chain
     */
    function systemCall(
        uint32 _destination,
        uint32 _optimisticSeconds,
        SystemEntity _recipient,
        bytes memory _data
    ) external;

    /**
     * @notice Calls a few system contracts using the given calldata for each call.
     * See `systemCall` for details on system calls.
     * Note: tx will revert if any of the calls revert, guaranteeing
     * that either all calls succeed or none.
     */
    function systemMultiCall(
        uint32 _destination,
        uint32 _optimisticSeconds,
        SystemEntity[] memory _recipients,
        bytes[] memory _dataArray
    ) external;

    /**
     * @notice Calls a few system contracts using the same calldata for each call.
     * See `systemCall` for details on system calls.
     * Note: tx will revert if any of the calls revert, guaranteeing
     * that either all calls succeed or none.
     */
    function systemMultiCall(
        uint32 _destination,
        uint32 _optimisticSeconds,
        SystemEntity[] memory _recipients,
        bytes memory _data
    ) external;

    /**
     * @notice Calls a single system contract a few times using the given calldata for each call.
     * See `systemCall` for details on system calls.
     * Note: tx will revert if any of the calls revert, guaranteeing
     * that either all calls succeed or none.
     */
    function systemMultiCall(
        uint32 _destination,
        uint32 _optimisticSeconds,
        SystemEntity _recipient,
        bytes[] memory _dataArray
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library MerkleList {
    /**
     * @notice Calculates merkle root for a list of given leafs.
     * Merkle Tree is constructed by padding the list with ZERO values for leafs
     * until list length is a power of two.
     * Merkle Root is calculated for the constructed tree, and recorded in leafs[0].
     * Note: `leafs` values are overwritten in the process to avoid excessive memory allocations.
     * Caller is expected not to allocate memory for the leafs list, and only use leafs[0] value,
     * which is guaranteed to contain the calculated merkle root.
     * @param hashes    List of leafs for the merkle tree (to be overwritten)
     */
    function calculateRoot(bytes32[] memory hashes) internal pure {
        // Use ZERO as value for "extra leafs".
        // Later this will be tracking the value of a "zero node" on the current tree level.
        bytes32 zeroHash = bytes32(0);
        uint256 levelLength = hashes.length;
        // We will be iterating from the "leafs level" up to the "root level" of the Merkle Tree.
        // For every level we will only record "significant values", i.e. not equal to `zeroHash`
        // Repeat until we only have a single hash: this would be the root of the tree
        while (levelLength > 1) {
            // Let H be the height of the "current level". H = 0 for the "root level".
            // Invariant: hashes[0 .. length) are "current level" tree nodes
            // Invariant: zeroHash is the value for nodes with indexes [length .. 2**H)

            // Iterate over every pair of (leftChild, rightChild) on the current level
            for (uint256 leftIndex = 0; leftIndex < levelLength; leftIndex += 2) {
                uint256 rightIndex = leftIndex + 1;
                bytes32 leftChild = hashes[leftIndex];
                // Note: rightChild might be zeroHash
                bytes32 rightChild = rightIndex < levelLength ? hashes[rightIndex] : zeroHash;
                // Record the parent hash in the same array. This will not affect
                // further calculations for the same level: (leftIndex >> 1) <= leftIndex.
                hashes[leftIndex >> 1] = keccak256(bytes.concat(leftChild, rightChild));
            }
            // Update value for the "zero hash"
            zeroHash = keccak256(bytes.concat(zeroHash, zeroHash));
            // Set length for the "parent level"
            levelLength = (levelLength + 1) >> 1;
        }
    }

    function calculateProof(
        bytes32[] memory hashes,
        uint256 index,
        bytes32[] memory proof
    ) internal pure {
        // proof[0] is already set up
        uint256 height = 0;

        // Use ZERO as value for "extra leafs".
        // Later this will be tracking the value of a "zero node" on the current tree level.
        bytes32 zeroHash = bytes32(0);
        uint256 levelLength = hashes.length;

        // We will be iterating from the "leafs level" up to the "root level" of the Merkle Tree.
        // For every level we will only record "significant values", i.e. not equal to `zeroHash`
        // Repeat until we only have a single hash: this would be the root of the tree
        while (levelLength > 1) {
            // Use sibling for the merkle proof
            proof[++height] = (index ^ 1 < levelLength) ? hashes[index ^ 1] : zeroHash;

            // Let H be the height of the "current level". H = 0 for the "root level".
            // Invariant: hashes[0 .. length) are "current level" tree nodes
            // Invariant: zeroHash is the value for nodes with indexes [length .. 2**H)

            // Iterate over every pair of (leftChild, rightChild) on the current level
            for (uint256 leftIndex = 0; leftIndex < levelLength; leftIndex += 2) {
                uint256 rightIndex = leftIndex + 1;
                bytes32 leftChild = hashes[leftIndex];
                // Note: rightChild might be zeroHash
                bytes32 rightChild = rightIndex < levelLength ? hashes[rightIndex] : zeroHash;
                // Record the parent hash in the same array. This will not affect
                // further calculations for the same level: (leftIndex >> 1) <= leftIndex.
                hashes[leftIndex >> 1] = keccak256(bytes.concat(leftChild, rightChild));
            }
            // Update value for the "zero hash"
            zeroHash = keccak256(bytes.concat(zeroHash, zeroHash));
            // Set length for the "parent level"
            levelLength = (levelLength + 1) >> 1;
            // Traverse to parent node
            index >>= 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library AgentSet {
    /**
     * @notice Information about an active Agent, optimized to fit in one word of storage.
     * @dev We are storing both Notaries (domain > 0) and Guards (domain == 0) this way.
     * @param domain    Domain where Agent is active
     * @param index     Agent position in _agents[domain] array, plus 1 because index 0
     *                  means Agent is not active on any domain
     */
    struct AgentIndex {
        uint32 domain;
        uint224 index;
    }

    /**
     * @notice Information about all active agents for all domains.
     * @dev We are storing both Notaries (domain > 0) and Guards (domain == 0) this way.
     * @param _agents   List of active agents for each domain
     * @param _indexes  Information about every active agent
     */
    struct DomainAddressSet {
        // (domain => [list of agents for the domain])
        mapping(uint32 => address[]) _agents;
        // (agent => agentIndex)
        mapping(address => AgentIndex) _indexes;
    }

    /**
     * @notice Add an agent to a given domain's set of active agents. O(1)
     * @dev Will not add the agent, if it is already active on another domain.
     *
     * Returns true if the agent was added to the domain, that is
     * if it was not already active on any domain.
     */
    function add(
        DomainAddressSet storage set,
        uint32 domain,
        address account
    ) internal returns (bool) {
        (bool isActive, ) = contains(set, account);
        if (isActive) return false;
        set._agents[domain].push(account);
        // The agent is stored at length-1, but we add 1 to all indexes
        // and use 0 as a sentinel value
        set._indexes[account] = AgentIndex({
            domain: domain,
            index: uint224(set._agents[domain].length)
        });
        return true;
    }

    /**
     * @notice Remove an agent from a given domain's set of active agents. O(1)
     * @dev Will not remove the agent, if it is not active on the given domain.
     *
     * Returns true if the agent was removed from the domain, that is
     * if it was active on that domain.
     */
    function remove(
        DomainAddressSet storage set,
        uint32 domain,
        address account
    ) internal returns (bool) {
        AgentIndex memory agentIndex = set._indexes[account];
        // Do nothing if agent is not active, or is active but on another domain
        if (agentIndex.index == 0 || agentIndex.domain != domain) return false;
        uint256 toDeleteIndex = agentIndex.index - 1;
        // To delete an Agent from the array in O(1),
        // we swap the Agent to delete with the last one in the array,
        // and then remove the last Agent (sometimes called as 'swap and pop').
        address[] storage agents = set._agents[domain];
        uint256 lastIndex = agents.length - 1;
        if (lastIndex != toDeleteIndex) {
            address lastAgent = agents[lastIndex];
            // Move the last Agent to the index where the Agent to delete is
            agents[toDeleteIndex] = lastAgent;
            // Update the index for the moved Agent (use deleted agent's value)
            set._indexes[lastAgent].index = agentIndex.index;
        }
        // Delete the slot where the moved Agent was stored
        agents.pop();
        // Delete the index for the deleted slot
        delete set._indexes[account];
        return true;
    }

    /**
     * @notice Returns true if the agent is active on any domain,
     * and the domain where the agent is active. O(1)
     */
    function contains(DomainAddressSet storage set, address account)
        internal
        view
        returns (bool isActive, uint32 domain)
    {
        AgentIndex memory agentIndex = set._indexes[account];
        if (agentIndex.index != 0) {
            isActive = true;
            domain = agentIndex.domain;
        }
    }

    /**
     * @notice Returns true if the agent is active on the given domain. O(1)
     */
    function contains(
        DomainAddressSet storage set,
        uint32 domain,
        address account
    ) internal view returns (bool) {
        // Read from storage just once
        AgentIndex memory agentIndex = set._indexes[account];
        // Check that agent domain matches, and that agent is active
        return agentIndex.domain == domain && agentIndex.index != 0;
    }

    /**
     * @notice Returns a number of active agents for the given domain. O(1)
     */
    function length(DomainAddressSet storage set, uint32 domain) internal view returns (uint256) {
        return set._agents[domain].length;
    }

    /**
     * @notice Returns the agent stored at position `index` in the given domain's set. O(1).
     * @dev Note that there are no guarantees on the ordering of agents inside the
     * array, and it may change when more agents are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        DomainAddressSet storage set,
        uint32 domain,
        uint256 index
    ) internal view returns (address) {
        return set._agents[domain][index];
    }

    /**
     * @notice Return the entire set of domain's agents in an array.
     *
     * @dev This operation will copy the entire storage to memory, which can be quite expensive.
     * This is designed to mostly be used by view accessors that are queried without any gas fees.
     * Developers should keep in mind that this function has an unbounded cost, and using it as part
     * of a state-changing function may render the function uncallable if the set grows to a point
     * where copying to memory consumes too much gas to fit in a block.
     */
    function values(DomainAddressSet storage set, uint32 domain)
        internal
        view
        returns (address[] memory)
    {
        return set._agents[domain];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString, Signature } from "./ByteString.sol";
import { TypedMemView } from "./TypedMemView.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Auth {
    using ByteString for Signature;
    using TypedMemView for bytes29;

    /**
     * @notice Returns an Ethereum Signed Message, created from a `_view`.
     * @dev This produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     * See {recoverSigner}.
     * @param _dataView Memory view over the data that needs to be signed
     * @return digest   An Ethereum Signed Message for the given data
     */
    function toEthSignedMessageHash(bytes29 _dataView) internal pure returns (bytes32 digest) {
        // Derive hash of the original data and use that for forming an Ethereum Signed Message
        digest = ECDSA.toEthSignedMessageHash(_dataView.keccak());
    }

    /**
     * @notice Recovers signer from digest and signature.
     * @dev IMPORTANT: `_digest` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     * @param _digest       Digest that was signed
     * @param _signature    Memory view over `signer` signature on `_digest`
     * @return signer       Address that signed the data
     */
    function recoverSigner(bytes32 _digest, Signature _signature)
        internal
        pure
        returns (address signer)
    {
        (bytes32 r, bytes32 s, uint8 v) = _signature.toRSV();
        signer = ECDSA.recover({ hash: _digest, r: r, s: s, v: v });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract AgentRegistryEvents {
    /*
     * @notice Emitted when a new Agent is added.
     * @param domain    Domain where a Agent was added
     * @param account   Address of the added agent
     */
    event AgentAdded(uint32 indexed domain, address indexed account);

    /**
     * @notice Emitted when an Agent is removed.
     * @param domain    Domain where a removed Agent was active
     * @param account   Address of the removed agent
     */
    event AgentRemoved(uint32 indexed domain, address indexed account);

    /**
     * @notice Emitted when an Agent is slashed.
     * @param domain    Domain where a slashed Agent was active
     * @param account   Address of the slashed agent
     */
    event AgentSlashed(uint32 indexed domain, address indexed account);

    /**
     * @notice Emitted when the first agent is added for the domain
     * @param domain    Domain where the first Agent was added
     */
    event DomainActivated(uint32 indexed domain);

    /**
     * @notice Emitted when the last agent is removed from the domain
     * @param domain    Domain where the last Agent was removed
     */
    event DomainDeactivated(uint32 indexed domain);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAgentRegistry {
    /**
     * @notice Returns the amount of active agents for the given domain.
     * Note: will return the amount of active Guards, if `_domain == 0`.
     */
    function amountAgents(uint32 _domain) external view returns (uint256);

    /**
     * @notice Returns the amount of active domains.
     * @dev This always excludes the zero domain, which is used for storing the guards.
     */
    function amountDomains() external view returns (uint256);

    /**
     * @notice Returns i-th agent for a given domain.
     * @dev Will revert if index is out of range.
     * Note: domain == 0 refers to a Guard, while _domain > 0 refers to a Notary.
     */
    function getAgent(uint32 _domain, uint256 _agentIndex) external view returns (address);

    /**
     * @notice Returns i-th domain from the list of active domains.
     * @dev Will revert if index is out of range.
     * Note: this never returns the zero domain, which is used for storing the guards.
     */
    function getDomain(uint256 _domainIndex) external view returns (uint32);

    /**
     * @notice Returns all active Agents for a given domain in an array.
     * Note: will return the list of active Guards, if `_domain == 0`.
     * @dev This copies storage into memory, so can consume a lof of gas, if
     * amount of agents is large (see EnumerableSet.values())
     */
    function allAgents(uint32 _domain) external view returns (address[] memory);

    /**
     * @notice Returns all domains having at least one active Notary in an array.
     * @dev This always excludes the zero domain, which is used for storing the guards.
     */
    function allDomains() external view returns (uint32[] memory domains_);

    /**
     * @notice Returns true if the agent is active on any domain.
     * Note: that includes both Guards and Notaries.
     * @return isActive Whether the account is an active agent on any of the domains
     * @return domain   Domain, where the account is an active agent
     */
    function isActiveAgent(address _account) external view returns (bool isActive, uint32 domain);

    /**
     * @notice Returns true if the agent is active on the given domain.
     * Note: domain == 0 refers to a Guard, while _domain > 0 refers to a Notary.
     */
    function isActiveAgent(uint32 _domain, address _account) external view returns (bool);

    /**
     * @notice Returns true if there is at least one active notary for the domain
     * Note: will return false for `_domain == 0`, even if there are active Guards.
     */
    function isActiveDomain(uint32 _domain) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
        return _values(set._inner);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AgentInfo, SystemEntity } from "../libs/Structures.sol";
import { InterfaceSystemRouter } from "./InterfaceSystemRouter.sol";

interface ISystemContract {
    /**
     * @notice Receive a system call indicating the off-chain agent needs to be slashed.
     * @param _rootSubmittedAt  Time when merkle root (used for proving this message) was submitted
     * @param _callOrigin       Domain where the system call originated
     * @param _caller           Entity which performed the system call
     * @param _info             Information about agent to slash
     */
    function slashAgent(
        uint256 _rootSubmittedAt,
        uint32 _callOrigin,
        SystemEntity _caller,
        AgentInfo memory _info
    ) external;

    /**
     * @notice Receive a system call indicating the off-chain agent status needs to be updated.
     * @param _rootSubmittedAt  Time when merkle root (used for proving this message) was submitted
     * @param _callOrigin       Domain where the system call originated
     * @param _caller           Entity which performed the system call
     * @param _info             Information about agent to sync
     */
    function syncAgent(
        uint256 _rootSubmittedAt,
        uint32 _callOrigin,
        SystemEntity _caller,
        AgentInfo memory _info
    ) external;

    function setSystemRouter(InterfaceSystemRouter _systemRouter) external;

    function systemRouter() external view returns (InterfaceSystemRouter);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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