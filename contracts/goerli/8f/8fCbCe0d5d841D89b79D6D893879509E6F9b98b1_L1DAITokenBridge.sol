// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IMailbox, L2Log, L2Message} from "../../zksync/interfaces/IZkSync.sol";

/// @author Matter Labs
interface IL1Bridge {
    event DepositInitiated(address indexed from, address indexed to, address indexed l1Token, uint256 amount);

    event WithdrawalFinalized(address indexed to, address indexed l1Token, uint256 amount);

    event ClaimedFailedDeposit(address indexed to, address indexed l1Token, uint256 amount);

    function isWithdrawalFinalized(uint256 _l2BlockNumber, uint256 _l2MessageIndex) external view returns (bool);

    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        uint256 _l2TxGasLimit,
        uint256 _l2TxGasPerPubdataByte
    ) external payable returns (bytes32 txHash);

    function claimFailedDeposit(
        address _depositSender,
        address _l1Token,
        bytes32 _l2TxHash,
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes32[] calldata _merkleProof
    ) external;

    function finalizeWithdrawal(
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external;

    function l2TokenAddress(address _l1Token) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAllowList {
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Access mode of target contract is changed
    event UpdateAccessMode(address indexed target, AccessMode previousMode, AccessMode newMode);

    /// @notice Permission to call is changed
    event UpdateCallPermission(address indexed caller, address indexed target, bytes4 indexed functionSig, bool status);

    /// @notice Type of access to a specific contract includes three different modes
    /// @param Closed No one has access to the contract
    /// @param SpecialAccessOnly Any address with granted special access can interact with a contract (see `hasSpecialAccessToCall`)
    /// @param Public Everyone can interact with a contract
    enum AccessMode {
        Closed,
        SpecialAccessOnly,
        Public
    }

    /// @dev A struct that contains withdrawal limit data of a token
    /// @param withdrawalLimitation Whether any withdrawal limitation is placed or not
    /// @param withdrawalFactor Percentage of allowed withdrawal. A withdrawalFactor of 10 means maximum %10 of bridge balance can be withdrawn
    struct Withdrawal {
        bool withdrawalLimitation;
        uint256 withdrawalFactor;
    }

    /// @dev A struct that contains deposit limit data of a token
    /// @param depositLimitation Whether any deposit limitation is placed or not
    /// @param depositCap The maximum amount that can be deposited.
    struct Deposit {
        bool depositLimitation;
        uint256 depositCap;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function getAccessMode(address _target) external view returns (AccessMode);

    function hasSpecialAccessToCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    function canCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    function getTokenWithdrawalLimitData(address _l1Token) external view returns (Withdrawal memory);

    function getTokenDepositLimitData(address _l1Token) external view returns (Deposit memory);

    /*//////////////////////////////////////////////////////////////
                           ALLOW LIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBatchAccessMode(address[] calldata _targets, AccessMode[] calldata _accessMode) external;

    function setAccessMode(address _target, AccessMode _accessMode) external;

    function setBatchPermissionToCall(
        address[] calldata _callers,
        address[] calldata _targets,
        bytes4[] calldata _functionSigs,
        bool[] calldata _enables
    ) external;

    function setPermissionToCall(
        address _caller,
        address _target,
        bytes4 _functionSig,
        bool _enable
    ) external;

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setWithdrawalLimit(
        address _l1Token,
        bool _withdrawalLimitation,
        uint256 _withdrawalFactor
    ) external;

    /*//////////////////////////////////////////////////////////////
                           DEPOSIT LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setDepositLimit(
        address _l1Token,
        bool _depositLimitation,
        uint256 _depositCap
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library UncheckedMath {
    function uncheckedInc(uint256 _number) internal pure returns (uint256) {
        unchecked {
            return _number + 1;
        }
    }

    function uncheckedAdd(uint256 _lhs, uint256 _rhs) internal pure returns (uint256) {
        unchecked {
            return _lhs + _rhs;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Diamond.sol";

interface IDiamondCut {
    function proposeTransparentUpgrade(Diamond.DiamondCutData calldata _diamondCut, uint40 _proposalId) external;

    function proposeShadowUpgrade(bytes32 _proposalHash, uint40 _proposalId) external;

    function cancelUpgradeProposal(bytes32 _proposedUpgradeHash) external;

    function securityCouncilUpgradeApprove(bytes32 _upgradeProposalHash) external;

    function executeUpgrade(Diamond.DiamondCutData calldata _diamondCut, bytes32 _proposalSalt) external;

    function freezeDiamond() external;

    function unfreezeDiamond() external;

    function upgradeProposalHash(
        Diamond.DiamondCutData calldata _diamondCut,
        uint256 _proposalId,
        bytes32 _salt
    ) external pure returns (bytes32);

    event ProposeTransparentUpgrade(
        Diamond.DiamondCutData diamondCut,
        uint256 indexed proposalId,
        bytes32 proposalSalt
    );

    event ProposeShadowUpgrade(uint256 indexed proposalId, bytes32 indexed proposalHash);

    event CancelUpgradeProposal(uint256 indexed proposalId, bytes32 indexed proposalHash);

    event SecurityCouncilUpgradeApprove(uint256 indexed proposalId, bytes32 indexed proposalHash);

    event ExecuteUpgrade(uint256 indexed proposalId, bytes32 indexed proposalHash, bytes32 proposalSalt);

    event Freeze();

    event Unfreeze();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExecutor {
    /// @notice Rollup block stored data
    /// @param blockNumber Rollup block number
    /// @param blockHash Hash of L2 block
    /// @param indexRepeatedStorageChanges The serial number of the shortcut index that's used as a unique identifier for storage keys that were used twice or more
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param priorityOperationsHash Hash of all priority operations from this block
    /// @param l2LogsTreeRoot Root hash of tree that contains L2 -> L1 messages from this block
    /// @param timestamp Rollup block timestamp, have the same format as Ethereum block constant
    /// @param commitment Verified input for the zkSync circuit
    struct StoredBlockInfo {
        uint64 blockNumber;
        bytes32 blockHash;
        uint64 indexRepeatedStorageChanges;
        uint256 numberOfLayer1Txs;
        bytes32 priorityOperationsHash;
        bytes32 l2LogsTreeRoot;
        uint256 timestamp;
        bytes32 commitment;
    }

    /// @notice Data needed to commit new block
    /// @param blockNumber Number of the committed block
    /// @param timestamp Unix timestamp denoting the start of the block execution
    /// @param indexRepeatedStorageChanges The serial number of the shortcut index that's used as a unique identifier for storage keys that were used twice or more
    /// @param newStateRoot The state root of the full state tree
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param l2LogsTreeRoot The root hash of the tree that contains all L2 -> L1 logs in the block
    /// @param priorityOperationsHash Hash of all priority operations from this block
    /// @param initialStorageChanges Storage write access as a concatenation key-value
    /// @param repeatedStorageChanges Storage write access as a concatenation index-value
    /// @param l2Logs concatenation of all L2 -> L1 logs in the block
    /// @param l2ArbitraryLengthMessages array of hash preimages that were sent as value of L2 logs by special system L2 contract
    /// @param factoryDeps array of l2 bytecodes that were marked as known on L2
    struct CommitBlockInfo {
        uint64 blockNumber;
        uint64 timestamp;
        uint64 indexRepeatedStorageChanges;
        bytes32 newStateRoot;
        uint256 numberOfLayer1Txs;
        bytes32 l2LogsTreeRoot;
        bytes32 priorityOperationsHash;
        bytes initialStorageChanges;
        bytes repeatedStorageChanges;
        bytes l2Logs;
        bytes[] l2ArbitraryLengthMessages;
        bytes[] factoryDeps;
    }

    /// @notice Recursive proof input data (individual commitments are constructed onchain)
    struct ProofInput {
        uint256[] recursiveAggregationInput;
        uint256[] serializedProof;
    }

    function commitBlocks(StoredBlockInfo calldata _lastCommittedBlockData, CommitBlockInfo[] calldata _newBlocksData)
        external;

    function proveBlocks(
        StoredBlockInfo calldata _prevBlock,
        StoredBlockInfo[] calldata _committedBlocks,
        ProofInput calldata _proof
    ) external;

    function executeBlocks(StoredBlockInfo[] calldata _blocksData) external;

    function revertBlocks(uint256 _newLastBlock) external;

    /// @notice Event emitted when a block is committed
    event BlockCommit(uint256 indexed blockNumber, bytes32 indexed blockHash, bytes32 indexed commitment);

    /// @notice Event emitted when blocks are verified
    event BlocksVerification(uint256 indexed previousLastVerifiedBlock, uint256 indexed currentLastVerifiedBlock);

    /// @notice Event emitted when a block is executed
    event BlockExecution(uint256 indexed blockNumber, bytes32 indexed blockHash, bytes32 indexed commitment);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint256 totalBlocksCommitted, uint256 totalBlocksVerified, uint256 totalBlocksExecuted);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Storage.sol";
import "../libraries/PriorityQueue.sol";
import {VerifierParams} from "../Storage.sol";

interface IGetters {
    /*//////////////////////////////////////////////////////////////
                            CUSTOM GETTERS
    //////////////////////////////////////////////////////////////*/

    function getVerifier() external view returns (address);

    function getGovernor() external view returns (address);

    function getPendingGovernor() external view returns (address);

    function getTotalBlocksCommitted() external view returns (uint256);

    function getTotalBlocksVerified() external view returns (uint256);

    function getTotalBlocksExecuted() external view returns (uint256);

    function getTotalPriorityTxs() external view returns (uint256);

    function getFirstUnprocessedPriorityTx() external view returns (uint256);

    function getPriorityQueueSize() external view returns (uint256);

    function priorityQueueFrontOperation() external view returns (PriorityOperation memory);

    function isValidator(address _address) external view returns (bool);

    function l2LogsRootHash(uint256 _blockNumber) external view returns (bytes32 hash);

    function storedBlockHash(uint256 _blockNumber) external view returns (bytes32);

    function getL2BootloaderBytecodeHash() external view returns (bytes32);

    function getL2DefaultAccountBytecodeHash() external view returns (bytes32);

    function getVerifierParams() external view returns (VerifierParams memory);

    function isDiamondStorageFrozen() external view returns (bool);

    function getSecurityCouncil() external view returns (address);

    function getUpgradeProposalState() external view returns (UpgradeState);

    function getProposedUpgradeHash() external view returns (bytes32);

    function getProposedUpgradeTimestamp() external view returns (uint256);

    function getCurrentProposalId() external view returns (uint256);

    function isApprovedBySecurityCouncil() external view returns (bool);

    function getpriorityTxMaxGasLimit() external view returns (uint256);

    function isEthWithdrawalFinalized(uint256 _l2BlockNumber, uint256 _l2MessageIndex) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                            DIAMOND LOUPE
    //////////////////////////////////////////////////////////////*/

    /// @notice Faсet structure compatible with the EIP-2535 diamond loupe
    /// @param addr The address of the facet contract
    /// @param selectors The NON-sorted array with selectors associated with facet
    struct Facet {
        address addr;
        bytes4[] selectors;
    }

    function facets() external view returns (Facet[] memory);

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory);

    function facetAddresses() external view returns (address[] memory facets);

    function facetAddress(bytes4 _selector) external view returns (address facet);

    function isFunctionFreezable(bytes4 _selector) external view returns (bool);

    function isFacetFreezable(address _facet) external view returns (bool isFreezable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Verifier.sol";
import "../Storage.sol";

interface IGovernance {
    function setPendingGovernor(address _newPendingGovernor) external;

    function acceptGovernor() external;

    function setValidator(address _validator, bool _active) external;

    function setL2BootloaderBytecodeHash(bytes32 _l2BootloaderBytecodeHash) external;

    function setL2DefaultAccountBytecodeHash(bytes32 _l2DefaultAccountBytecodeHash) external;

    function setPorterAvailability(bool _zkPorterIsAvailable) external;

    function setVerifier(Verifier _newVerifier) external;

    function setVerifierParams(VerifierParams calldata _newVerifierParams) external;

    function setPriorityTxMaxGasLimit(uint256 _newPriorityTxMaxGasLimit) external;

    /// @notice Сhanges to the bytecode that is used in L2 as a bootloader (start program)
    event NewL2BootloaderBytecodeHash(bytes32 indexed previousBytecodeHash, bytes32 indexed newBytecodeHash);

    /// @notice Сhanges to the bytecode that is used in L2 as a default account
    event NewL2DefaultAccountBytecodeHash(bytes32 indexed previousBytecodeHash, bytes32 indexed newBytecodeHash);

    /// @notice Porter availability status changes
    event IsPorterAvailableStatusUpdate(bool isPorterAvailable);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    /// @notice pendingGovernor is changed
    /// @dev Also emitted when new governor is accepted and in this case, `newPendingGovernor` would be zero address
    event NewPendingGovernor(address indexed oldPendingGovernor, address indexed newPendingGovernor);

    /// @notice Governor changed
    event NewGovernor(address indexed oldGovernor, address indexed newGovernor);

    /// @notice Verifier address changed
    event NewVerifier(address indexed oldVerifier, address indexed newVerifier);

    /// @notice Verifier address changed
    event NewVerifierParams(VerifierParams oldVerifierParams, VerifierParams newVerifierParams);

    /// @notice Priority transaction max L2 gas limit changed
    event NewPriorityTxMaxGasLimit(uint256 oldPriorityTxMaxGasLimit, uint256 newPriorityTxMaxGasLimit);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {L2Log, L2Message} from "../Storage.sol";

/// @dev The enum that represents the transaction execution status
/// @param Failure The transaction execution failed
/// @param Success The transaction execution succeeded
enum TxStatus {
    Failure,
    Success
}

interface IMailbox {
    /// @dev Structure that includes all fields of the L2 transaction
    /// @dev The hash of this structure is the "canonical L2 transaction hash" and can be used as a unique identifier of a tx
    /// @param txType The tx type number, depending on which the L2 transaction can be interpreted differently
    /// @param from The sender's address. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param to The recipient's address. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param gasLimit The L2 gas limit for L2 transaction. Analog to the `gasLimit` on an L1 transactions
    /// @param gasPerPubdataByteLimit Maximum number of L2 gas that will cost one byte of pubdata (every piece of data that will be stored on L1 as calldata)
    /// @param maxFeePerGas The absolute maximum sender willing to pay per unit of L2 gas to get the transaction included in a block. Analog to the EIP-1559 `maxFeePerGas` on an L1 transactions
    /// @param maxPriorityFeePerGas The additional fee that is paid directly to the validator to incentivize them to include the transaction in a block. Analog to the EIP-1559 `maxPriorityFeePerGas` on an L1 transactions
    /// @param paymaster The address of the EIP-4337 paymaster, that will pay fees for the transaction. `uint256` type for possible address format changes and maintaining backward compatibility
    /// @param nonce The nonce of the transaction. For L1->L2 transactions it is the priority operation Id.
    /// @param value The value to pass with the transaction
    /// @param reserved The fixed-length fields for usage in a future extension of transaction formats
    /// @param data The calldata that is transmitted for the transaction call
    /// @param signature An abstract set of bytes that are used for transaction authorization
    /// @param factoryDeps The set of L2 bytecode hashes whose preimages were shown on L1
    /// @param paymasterInput The arbitrary-length data that is used as a calldata to the paymaster pre-call
    /// @param reservedDynamic The arbitrary-length field for usage in a future extension of transaction formats
    struct L2CanonicalTransaction {
        uint256 txType;
        uint256 from;
        uint256 to;
        uint256 gasLimit;
        uint256 gasPerPubdataByteLimit;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 paymaster;
        uint256 nonce;
        uint256 value;
        // In the future, we might want to add some
        // new fields to the struct. The `txData` struct
        // is to be passed to account and any changes to its structure
        // would mean a breaking change to these accounts. To prevent this,
        // we should keep some fields as "reserved".
        // It is also recommended that their length is fixed, since
        // it would allow easier proof integration (in case we will need
        // some special circuit for preprocessing transactions).
        uint256[4] reserved;
        bytes data;
        bytes signature;
        uint256[] factoryDeps;
        bytes paymasterInput;
        // Reserved dynamic type for the future use-case. Using it should be avoided,
        // But it is still here, just in case we want to enable some additional functionality.
        bytes reservedDynamic;
    }

    /// @dev Internal structure that contains the parameters for the writePriorityOp
    /// internal function.
    /// @param sender The sender's address.
    /// @param txId The id of the priority transaction.
    /// @param l2Value The msg.value of the L2 transaction.
    /// @param contractAddressL2 The address of the contract on L2 to call.
    /// @param expirationTimestamp The timestamp by which the priority operation must be processed by the operator.
    /// @param l2GasLimit The limit of the L2 gas for the L2 transaction
    /// @param l2GasPricePerPubdata The price for a single pubdata byte in L2 gas.
    /// @param valueToMint The amount of ether that should be minted on L2 as the result of this transaction.
    /// @param refundRecipient The recipient of the refund for the transaction on L2. If the transaction fails, then
    /// this address will receive the `l2Value`.
    struct WritePriorityOpParams {
        address sender;
        uint256 txId;
        uint256 l2Value;
        address contractAddressL2;
        uint64 expirationTimestamp;
        uint256 l2GasLimit;
        uint256 l2GasPricePerPubdata;
        uint256 valueToMint;
        address refundRecipient;
    }

    function proveL2MessageInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Message calldata _message,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function proveL2LogInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Log memory _log,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function proveL1ToL2TransactionStatus(
        bytes32 _l2TxHash,
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes32[] calldata _merkleProof,
        TxStatus _status
    ) external view returns (bool);

    function serializeL2Transaction(
        uint256 _txId,
        uint256 _l2Value,
        address _sender,
        address _contractAddressL2,
        bytes calldata _calldata,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        bytes[] calldata _factoryDeps,
        uint256 _toMint,
        address _refundRecipient
    ) external pure returns (L2CanonicalTransaction memory);

    function finalizeEthWithdrawal(
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external;

    function requestL2Transaction(
        address _contractL2,
        uint256 _l2Value,
        bytes calldata _calldata,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        bytes[] calldata _factoryDeps,
        address _refundRecipient
    ) external payable returns (bytes32 canonicalTxHash);

    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);

    /// @notice New priority request event. Emitted when a request is placed into the priority queue
    /// @param txId Serial number of the priority operation
    /// @param txHash keccak256 hash of encoded transaction representation
    /// @param expirationTimestamp Timestamp up to which priority request should be processed
    /// @param transaction The whole transaction structure that is requested to be executed on L2
    /// @param factoryDeps An array of bytecodes that were shown in the L1 public data. Will be marked as known bytecodes in L2
    event NewPriorityRequest(
        uint256 txId,
        bytes32 txHash,
        uint64 expirationTimestamp,
        L2CanonicalTransaction transaction,
        bytes[] factoryDeps
    );

    /// @notice Emitted when the withdrawal is finalized on L1 and funds are released.
    /// @param to The address to which the funds were sent
    /// @param amount The amount of funds that were sent
    event EthWithdrawalFinalized(address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMailbox.sol";
import "./IGovernance.sol";
import "./IExecutor.sol";
import "./IDiamondCut.sol";
import "./IGetters.sol";

interface IZkSync is IMailbox, IGovernance, IExecutor, IDiamondCut, IGetters {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../common/libraries/UncheckedMath.sol";

/// @author Matter Labs
/// @notice The helper library for managing the EIP-2535 diamond proxy.
library Diamond {
    using UncheckedMath for uint256;
    using SafeCast for uint256;

    /// @dev Magic value that should be returned by diamond cut initialize contracts.
    /// @dev Used to distinguish calls to contracts that were supposed to be used as diamond initializer from other contracts.
    bytes32 constant DIAMOND_INIT_SUCCESS_RETURN_VALUE =
        0x33774e659306e47509050e97cb651e731180a42d458212294d30751925c551a2; // keccak256("diamond.zksync.init") - 1

    /// @dev Storage position of `DiamondStorage` structure.
    bytes32 constant DIAMOND_STORAGE_POSITION = 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131b; // keccak256("diamond.standard.diamond.storage") - 1;

    event DiamondCut(FacetCut[] facetCuts, address initAddress, bytes initCalldata);

    /// @dev Utility struct that contains associated facet & meta information of selector
    /// @param facetAddress address of the facet which is connected with selector
    /// @param selectorPosition index in `FacetToSelectors.selectors` array, where is selector stored
    /// @param isFreezable denotes whether the selector can be frozen.
    struct SelectorToFacet {
        address facetAddress;
        uint16 selectorPosition;
        bool isFreezable;
    }

    /// @dev Utility struct that contains associated selectors & meta information of facet
    /// @param selectors list of all selectors that belong to the facet
    /// @param facetPosition index in `DiamondStorage.facets` array, where is facet stored
    struct FacetToSelectors {
        bytes4[] selectors;
        uint16 facetPosition;
    }

    /// @notice The structure that holds all diamond proxy associated parameters
    /// @dev According to the EIP-2535 should be stored on a special storage key - `DIAMOND_STORAGE_POSITION`
    /// @param selectorToFacet A mapping from the selector to the facet address and its meta information
    /// @param facetToSelectors A mapping from facet address to its selector with meta information
    /// @param facets The array of all unique facet addresses that belong to the diamond proxy
    /// @param isFrozen Denotes whether the diamond proxy is frozen and all freezable facets are not accessible
    struct DiamondStorage {
        mapping(bytes4 => SelectorToFacet) selectorToFacet;
        mapping(address => FacetToSelectors) facetToSelectors;
        address[] facets;
        bool isFrozen;
    }

    /// @dev Parameters for diamond changes that touch one of the facets
    /// @param facet The address of facet that's affected by the cut
    /// @param action The action that is made on the facet
    /// @param isFreezable Denotes whether the facet & all their selectors can be frozen
    /// @param selectors An array of unique selectors that belongs to the facet address
    struct FacetCut {
        address facet;
        Action action;
        bool isFreezable;
        bytes4[] selectors;
    }

    /// @dev Structure of the diamond proxy changes
    /// @param facetCuts The set of changes (adding/removing/replacement) of implementation contracts
    /// @param initAddress The address that's delegate called after setting up new facet changes
    /// @param initCalldata Calldata for the delegate call to `initAddress`
    struct DiamondCutData {
        FacetCut[] facetCuts;
        address initAddress;
        bytes initCalldata;
    }

    /// @dev Type of change over diamond: add/replace/remove facets
    enum Action {
        Add,
        Replace,
        Remove
    }

    /// @return diamondStorage The pointer to the storage where all specific diamond proxy parameters stored
    function getDiamondStorage() internal pure returns (DiamondStorage storage diamondStorage) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            diamondStorage.slot := position
        }
    }

    /// @dev Add/replace/remove any number of selectors and optionally execute a function with delegatecall
    /// @param _diamondCut Diamond's facet changes and the parameters to optional initialization delegatecall
    function diamondCut(DiamondCutData memory _diamondCut) internal {
        FacetCut[] memory facetCuts = _diamondCut.facetCuts;
        address initAddress = _diamondCut.initAddress;
        bytes memory initCalldata = _diamondCut.initCalldata;
        uint256 facetCutsLength = facetCuts.length;
        for (uint256 i = 0; i < facetCutsLength; i = i.uncheckedInc()) {
            Action action = facetCuts[i].action;
            address facet = facetCuts[i].facet;
            bool isFacetFreezable = facetCuts[i].isFreezable;
            bytes4[] memory selectors = facetCuts[i].selectors;

            require(selectors.length > 0, "B"); // no functions for diamond cut

            if (action == Action.Add) {
                _addFunctions(facet, selectors, isFacetFreezable);
            } else if (action == Action.Replace) {
                _replaceFunctions(facet, selectors, isFacetFreezable);
            } else if (action == Action.Remove) {
                _removeFunctions(facet, selectors);
            } else {
                revert("C"); // undefined diamond cut action
            }
        }

        _initializeDiamondCut(initAddress, initCalldata);
        emit DiamondCut(facetCuts, initAddress, initCalldata);
    }

    /// @dev Add new functions to the diamond proxy
    /// NOTE: expect but NOT enforce that `_selectors` is NON-EMPTY array
    function _addFunctions(
        address _facet,
        bytes4[] memory _selectors,
        bool _isFacetFreezable
    ) private {
        DiamondStorage storage ds = getDiamondStorage();

        require(_facet != address(0), "G"); // facet with zero address cannot be added

        // Add facet to the list of facets if the facet address is new one
        _saveFacetIfNew(_facet);

        uint256 selectorsLength = _selectors.length;
        for (uint256 i = 0; i < selectorsLength; i = i.uncheckedInc()) {
            bytes4 selector = _selectors[i];
            SelectorToFacet memory oldFacet = ds.selectorToFacet[selector];
            require(oldFacet.facetAddress == address(0), "J"); // facet for this selector already exists

            _addOneFunction(_facet, selector, _isFacetFreezable);
        }
    }

    /// @dev Change associated facets to already known function selectors
    /// NOTE: expect but NOT enforce that `_selectors` is NON-EMPTY array
    function _replaceFunctions(
        address _facet,
        bytes4[] memory _selectors,
        bool _isFacetFreezable
    ) private {
        DiamondStorage storage ds = getDiamondStorage();

        require(_facet != address(0), "K"); // cannot replace facet with zero address

        uint256 selectorsLength = _selectors.length;
        for (uint256 i = 0; i < selectorsLength; i = i.uncheckedInc()) {
            bytes4 selector = _selectors[i];
            SelectorToFacet memory oldFacet = ds.selectorToFacet[selector];
            require(oldFacet.facetAddress != address(0), "L"); // it is impossible to replace the facet with zero address

            _removeOneFunction(oldFacet.facetAddress, selector);
            // Add facet to the list of facets if the facet address is a new one
            _saveFacetIfNew(_facet);
            _addOneFunction(_facet, selector, _isFacetFreezable);
        }
    }

    /// @dev Remove association with function and facet
    /// NOTE: expect but NOT enforce that `_selectors` is NON-EMPTY array
    function _removeFunctions(address _facet, bytes4[] memory _selectors) private {
        DiamondStorage storage ds = getDiamondStorage();

        require(_facet == address(0), "a1"); // facet address must be zero

        uint256 selectorsLength = _selectors.length;
        for (uint256 i = 0; i < selectorsLength; i = i.uncheckedInc()) {
            bytes4 selector = _selectors[i];
            SelectorToFacet memory oldFacet = ds.selectorToFacet[selector];
            require(oldFacet.facetAddress != address(0), "a2"); // Can't delete a non-existent facet

            _removeOneFunction(oldFacet.facetAddress, selector);
        }
    }

    /// @dev Add address to the list of known facets if it is not on the list yet
    /// NOTE: should be called ONLY before adding a new selector associated with the address
    function _saveFacetIfNew(address _facet) private {
        DiamondStorage storage ds = getDiamondStorage();

        uint256 selectorsLength = ds.facetToSelectors[_facet].selectors.length;
        // If there are no selectors associated with facet then save facet as new one
        if (selectorsLength == 0) {
            ds.facetToSelectors[_facet].facetPosition = ds.facets.length.toUint16();
            ds.facets.push(_facet);
        }
    }

    /// @dev Add one function to the already known facet
    /// NOTE: It is expected but NOT enforced that:
    /// - `_facet` is NON-ZERO address
    /// - `_facet` is already stored address in `DiamondStorage.facets`
    /// - `_selector` is NOT associated by another facet
    function _addOneFunction(
        address _facet,
        bytes4 _selector,
        bool _isSelectorFreezable
    ) private {
        DiamondStorage storage ds = getDiamondStorage();

        uint16 selectorPosition = (ds.facetToSelectors[_facet].selectors.length).toUint16();

        // if selectorPosition is nonzero, it means it is not a new facet
        // so the freezability of the first selector must be matched to _isSelectorFreezable
        // so all the selectors in a facet will have the same freezability
        if (selectorPosition != 0) {
            bytes4 selector0 = ds.facetToSelectors[_facet].selectors[0];
            require(_isSelectorFreezable == ds.selectorToFacet[selector0].isFreezable, "J1");
        }

        ds.selectorToFacet[_selector] = SelectorToFacet({
            facetAddress: _facet,
            selectorPosition: selectorPosition,
            isFreezable: _isSelectorFreezable
        });
        ds.facetToSelectors[_facet].selectors.push(_selector);
    }

    /// @dev Remove one associated function with facet
    /// NOTE: It is expected but NOT enforced that `_facet` is NON-ZERO address
    function _removeOneFunction(address _facet, bytes4 _selector) private {
        DiamondStorage storage ds = getDiamondStorage();

        // Get index of `FacetToSelectors.selectors` of the selector and last element of array
        uint256 selectorPosition = ds.selectorToFacet[_selector].selectorPosition;
        uint256 lastSelectorPosition = ds.facetToSelectors[_facet].selectors.length - 1;

        // If the selector is not at the end of the array then move the last element to the selector position
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetToSelectors[_facet].selectors[lastSelectorPosition];

            ds.facetToSelectors[_facet].selectors[selectorPosition] = lastSelector;
            ds.selectorToFacet[lastSelector].selectorPosition = selectorPosition.toUint16();
        }

        // Remove last element from the selectors array
        ds.facetToSelectors[_facet].selectors.pop();

        // Finally, clean up the association with facet
        delete ds.selectorToFacet[_selector];

        // If there are no selectors for facet then remove the facet from the list of known facets
        if (lastSelectorPosition == 0) {
            _removeFacet(_facet);
        }
    }

    /// @dev remove facet from the list of known facets
    /// NOTE: It is expected but NOT enforced that there are no selectors associated with `_facet`
    function _removeFacet(address _facet) private {
        DiamondStorage storage ds = getDiamondStorage();

        // Get index of `DiamondStorage.facets` of the facet and last element of array
        uint256 facetPosition = ds.facetToSelectors[_facet].facetPosition;
        uint256 lastFacetPosition = ds.facets.length - 1;

        // If the facet is not at the end of the array then move the last element to the facet position
        if (facetPosition != lastFacetPosition) {
            address lastFacet = ds.facets[lastFacetPosition];

            ds.facets[facetPosition] = lastFacet;
            ds.facetToSelectors[lastFacet].facetPosition = facetPosition.toUint16();
        }

        // Remove last element from the facets array
        ds.facets.pop();
    }

    /// @dev Delegates call to the initialization address with provided calldata
    /// @dev Used as a final step of diamond cut to execute the logic of the initialization for changed facets
    function _initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init == address(0)) {
            require(_calldata.length == 0, "H"); // Non-empty calldata for zero address
        } else {
            // Do not check whether `_init` is a contract since later we check that it returns data.
            (bool success, bytes memory data) = _init.delegatecall(_calldata);
            require(success, "I"); // delegatecall failed

            // Check that called contract returns magic value to make sure that contract logic
            // supposed to be used as diamond cut initializer.
            require(data.length == 32, "lp");
            require(abi.decode(data, (bytes32)) == DIAMOND_INIT_SUCCESS_RETURN_VALUE, "lp1");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    // function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod, "x axis isn't valid");
        require(y < q_mod, "y axis isn't valid");
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2

        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs, "is not on curve");

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
            G2Point(
                [
                    0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                    0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
                ],
                [
                    0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                    0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
                ]
            );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        // https://eips.ethereum.org/EIPS/eip-197
        // Elliptic curve points are encoded as a Jacobian pair (X, Y) where the point at infinity is encoded as (0, 0)
        // TODO
        if (p.X == 0 && p.Y == 1) {
            p.Y = 0;
        }
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; ) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
            unchecked {
                ++i;
            }
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice The structure that contains meta information of the L2 transaction that was requested from L1
/// @dev The weird size of fields was selected specifically to minimize the structure storage size
/// @param canonicalTxHash Hashed L2 transaction data that is needed to process it
/// @param expirationTimestamp Expiration timestamp for this request (must be satisfied before)
/// @param layer2Tip Additional payment to the validator as an incentive to perform the operation
struct PriorityOperation {
    bytes32 canonicalTxHash;
    uint64 expirationTimestamp;
    uint192 layer2Tip;
}

/// @author Matter Labs
/// @dev The library provides the API to interact with the priority queue container
/// @dev Order of processing operations from queue - FIFO (Fist in - first out)
library PriorityQueue {
    using PriorityQueue for Queue;

    /// @notice Container that stores priority operations
    /// @param data The inner mapping that saves priority operation by its index
    /// @param head The pointer to the first unprocessed priority operation, equal to the tail if the queue is empty
    /// @param tail The pointer to the free slot
    struct Queue {
        mapping(uint256 => PriorityOperation) data;
        uint256 tail;
        uint256 head;
    }

    /// @notice Returns zero if and only if no operations were processed from the queue
    /// @return Index of the oldest priority operation that wasn't processed yet
    function getFirstUnprocessedPriorityTx(Queue storage _queue) internal view returns (uint256) {
        return _queue.head;
    }

    /// @return The total number of priority operations that were added to the priority queue, including all processed ones
    function getTotalPriorityTxs(Queue storage _queue) internal view returns (uint256) {
        return _queue.tail;
    }

    /// @return The total number of unprocessed priority operations in a priority queue
    function getSize(Queue storage _queue) internal view returns (uint256) {
        return uint256(_queue.tail - _queue.head);
    }

    /// @return Whether the priority queue contains no operations
    function isEmpty(Queue storage _queue) internal view returns (bool) {
        return _queue.tail == _queue.head;
    }

    /// @notice Add the priority operation to the end of the priority queue
    function pushBack(Queue storage _queue, PriorityOperation memory _operation) internal {
        // Save value into the stack to avoid double reading from the storage
        uint256 tail = _queue.tail;

        _queue.data[tail] = _operation;
        _queue.tail = tail + 1;
    }

    /// @return The first unprocessed priority operation from the queue
    function front(Queue storage _queue) internal view returns (PriorityOperation memory) {
        require(!_queue.isEmpty(), "D"); // priority queue is empty

        return _queue.data[_queue.head];
    }

    /// @notice Remove the first unprocessed priority operation from the queue
    /// @return priorityOperation that was popped from the priority queue
    function popFront(Queue storage _queue) internal returns (PriorityOperation memory priorityOperation) {
        require(!_queue.isEmpty(), "s"); // priority queue is empty

        // Save value into the stack to avoid double reading from the storage
        uint256 head = _queue.head;

        priorityOperation = _queue.data[head];
        delete _queue.data[head];
        _queue.head = head + 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PairingsBn254.sol";

library TranscriptLib {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns (PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/PairingsBn254.sol";
import "./libraries/TranscriptLib.sol";
import "../common/libraries/UncheckedMath.sol";

uint256 constant STATE_WIDTH = 4;
uint256 constant NUM_G2_ELS = 2;

struct VerificationKey {
    uint256 domain_size;
    uint256 num_inputs;
    PairingsBn254.Fr omega;
    PairingsBn254.G1Point[2] gate_selectors_commitments;
    PairingsBn254.G1Point[8] gate_setup_commitments;
    PairingsBn254.G1Point[STATE_WIDTH] permutation_commitments;
    PairingsBn254.G1Point lookup_selector_commitment;
    PairingsBn254.G1Point[4] lookup_tables_commitments;
    PairingsBn254.G1Point lookup_table_type_commitment;
    PairingsBn254.Fr[STATE_WIDTH - 1] non_residues;
    PairingsBn254.G2Point[NUM_G2_ELS] g2_elements;
}

contract Plonk4VerifierWithAccessToDNext {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLib for TranscriptLib.Transcript;

    using UncheckedMath for uint256;

    struct Proof {
        uint256[] input_values;
        // commitments
        PairingsBn254.G1Point[STATE_WIDTH] state_polys_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_parts_commitments;
        // openings
        PairingsBn254.Fr[STATE_WIDTH] state_polys_openings_at_z;
        PairingsBn254.Fr[1] state_polys_openings_at_z_omega; // TODO: not use array while there is only D_next
        PairingsBn254.Fr[1] gate_selectors_openings_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] copy_permutation_polys_openings_at_z;
        PairingsBn254.Fr copy_permutation_grand_product_opening_at_z_omega;
        PairingsBn254.Fr quotient_poly_opening_at_z;
        PairingsBn254.Fr linearization_poly_opening_at_z;
        // lookup commitments
        PairingsBn254.G1Point lookup_s_poly_commitment;
        PairingsBn254.G1Point lookup_grand_product_commitment;
        // lookup openings
        PairingsBn254.Fr lookup_s_poly_opening_at_z_omega;
        PairingsBn254.Fr lookup_grand_product_opening_at_z_omega;
        PairingsBn254.Fr lookup_t_poly_opening_at_z;
        PairingsBn254.Fr lookup_t_poly_opening_at_z_omega;
        PairingsBn254.Fr lookup_selector_poly_opening_at_z;
        PairingsBn254.Fr lookup_table_type_poly_opening_at_z;
        PairingsBn254.G1Point opening_proof_at_z;
        PairingsBn254.G1Point opening_proof_at_z_omega;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr zero;
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr[9] alpha_values;
        PairingsBn254.Fr eta;
        PairingsBn254.Fr beta_lookup;
        PairingsBn254.Fr gamma_lookup;
        PairingsBn254.Fr beta_plus_one;
        PairingsBn254.Fr beta_gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr z_omega;
        PairingsBn254.Fr z_minus_last_omega;
        PairingsBn254.Fr l_0_at_z;
        PairingsBn254.Fr l_n_minus_one_at_z;
        PairingsBn254.Fr t;
        PairingsBn254.G1Point tp;
    }

    function evaluate_l0_at_point(uint256 domain_size, PairingsBn254.Fr memory at)
        internal
        view
        returns (PairingsBn254.Fr memory num)
    {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory size_fe = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory den = at.copy();
        den.sub_assign(one);
        den.mul_assign(size_fe);

        den = den.inverse();

        num = at.pow(domain_size);
        num.sub_assign(one);
        num.mul_assign(den);
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        // (omega^i / N) / (X - omega^i) * (X^N - 1)
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function evaluate_vanishing(uint256 domain_size, PairingsBn254.Fr memory at)
        internal
        view
        returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function initialize_transcript(Proof memory proof, VerificationKey memory vk)
        internal
        pure
        returns (PartialVerifierState memory state)
    {
        TranscriptLib.Transcript memory transcript = TranscriptLib.new_transcript();

        for (uint256 i = 0; i < vk.num_inputs; i = i.uncheckedInc()) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < STATE_WIDTH; i = i.uncheckedInc()) {
            transcript.update_with_g1(proof.state_polys_commitments[i]);
        }

        state.eta = transcript.get_challenge();
        transcript.update_with_g1(proof.lookup_s_poly_commitment);

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.copy_permutation_grand_product_commitment);
        state.beta_lookup = transcript.get_challenge();
        state.gamma_lookup = transcript.get_challenge();
        transcript.update_with_g1(proof.lookup_grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_parts_commitments.length; i = i.uncheckedInc()) {
            transcript.update_with_g1(proof.quotient_poly_parts_commitments[i]);
        }
        state.z = transcript.get_challenge();

        transcript.update_with_fr(proof.quotient_poly_opening_at_z);

        for (uint256 i = 0; i < proof.state_polys_openings_at_z.length; i = i.uncheckedInc()) {
            transcript.update_with_fr(proof.state_polys_openings_at_z[i]);
        }

        for (uint256 i = 0; i < proof.state_polys_openings_at_z_omega.length; i = i.uncheckedInc()) {
            transcript.update_with_fr(proof.state_polys_openings_at_z_omega[i]);
        }
        for (uint256 i = 0; i < proof.gate_selectors_openings_at_z.length; i = i.uncheckedInc()) {
            transcript.update_with_fr(proof.gate_selectors_openings_at_z[i]);
        }
        for (uint256 i = 0; i < proof.copy_permutation_polys_openings_at_z.length; i = i.uncheckedInc()) {
            transcript.update_with_fr(proof.copy_permutation_polys_openings_at_z[i]);
        }

        state.z_omega = state.z.copy();
        state.z_omega.mul_assign(vk.omega);

        transcript.update_with_fr(proof.copy_permutation_grand_product_opening_at_z_omega);

        transcript.update_with_fr(proof.lookup_t_poly_opening_at_z);
        transcript.update_with_fr(proof.lookup_selector_poly_opening_at_z);
        transcript.update_with_fr(proof.lookup_table_type_poly_opening_at_z);
        transcript.update_with_fr(proof.lookup_s_poly_opening_at_z_omega);
        transcript.update_with_fr(proof.lookup_grand_product_opening_at_z_omega);
        transcript.update_with_fr(proof.lookup_t_poly_opening_at_z_omega);
        transcript.update_with_fr(proof.linearization_poly_opening_at_z);

        state.v = transcript.get_challenge();

        transcript.update_with_g1(proof.opening_proof_at_z);
        transcript.update_with_g1(proof.opening_proof_at_z_omega);

        state.u = transcript.get_challenge();
    }

    // compute some powers of challenge alpha([alpha^1, .. alpha^8])
    function compute_powers_of_alpha(PartialVerifierState memory state) public pure {
        require(state.alpha.value != 0);
        state.alpha_values[0] = PairingsBn254.new_fr(1);
        state.alpha_values[1] = state.alpha.copy();
        PairingsBn254.Fr memory current_alpha = state.alpha.copy();
        for (uint256 i = 2; i < state.alpha_values.length; i = i.uncheckedInc()) {
            current_alpha.mul_assign(state.alpha);
            state.alpha_values[i] = current_alpha.copy();
        }
    }

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        // we initialize all challenges beforehand, we can draw each challenge in its own place
        PartialVerifierState memory state = initialize_transcript(proof, vk);
        if (verify_quotient_evaluation(vk, proof, state) == false) {
            return false;
        }
        require(proof.state_polys_openings_at_z_omega.length == 1); // TODO

        PairingsBn254.G1Point memory quotient_result = proof.quotient_poly_parts_commitments[0].copy_g1();
        {
            // block scope
            PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);
            PairingsBn254.Fr memory current_z = z_in_domain_size.copy();
            PairingsBn254.G1Point memory tp;
            // start from i =1
            for (uint256 i = 1; i < proof.quotient_poly_parts_commitments.length; i = i.uncheckedInc()) {
                tp = proof.quotient_poly_parts_commitments[i].copy_g1();
                tp.point_mul_assign(current_z);
                quotient_result.point_add_assign(tp);

                current_z.mul_assign(z_in_domain_size);
            }
        }

        Queries memory queries = prepare_queries(vk, proof, state);
        queries.commitments_at_z[0] = quotient_result;
        queries.values_at_z[0] = proof.quotient_poly_opening_at_z;
        queries.commitments_at_z[1] = aggregated_linearization_commitment(vk, proof, state);
        queries.values_at_z[1] = proof.linearization_poly_opening_at_z;

        require(queries.commitments_at_z.length == queries.values_at_z.length);

        PairingsBn254.G1Point memory aggregated_commitment_at_z = queries.commitments_at_z[0];

        PairingsBn254.Fr memory aggregated_opening_at_z = queries.values_at_z[0];
        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.G1Point memory scaled;
        for (uint256 i = 1; i < queries.commitments_at_z.length; i = i.uncheckedInc()) {
            aggregation_challenge.mul_assign(state.v);
            scaled = queries.commitments_at_z[i].point_mul(aggregation_challenge);
            aggregated_commitment_at_z.point_add_assign(scaled);

            state.t = queries.values_at_z[i];
            state.t.mul_assign(aggregation_challenge);
            aggregated_opening_at_z.add_assign(state.t);
        }

        aggregation_challenge.mul_assign(state.v);

        PairingsBn254.G1Point memory aggregated_commitment_at_z_omega = queries.commitments_at_z_omega[0].point_mul(
            aggregation_challenge
        );
        PairingsBn254.Fr memory aggregated_opening_at_z_omega = queries.values_at_z_omega[0];
        aggregated_opening_at_z_omega.mul_assign(aggregation_challenge);
        for (uint256 i = 1; i < queries.commitments_at_z_omega.length; i = i.uncheckedInc()) {
            aggregation_challenge.mul_assign(state.v);

            scaled = queries.commitments_at_z_omega[i].point_mul(aggregation_challenge);
            aggregated_commitment_at_z_omega.point_add_assign(scaled);

            state.t = queries.values_at_z_omega[i];
            state.t.mul_assign(aggregation_challenge);
            aggregated_opening_at_z_omega.add_assign(state.t);
        }

        return
            final_pairing(
                vk.g2_elements,
                proof,
                state,
                aggregated_commitment_at_z,
                aggregated_commitment_at_z_omega,
                aggregated_opening_at_z,
                aggregated_opening_at_z_omega
            );
    }

    function verify_quotient_evaluation(
        VerificationKey memory vk,
        Proof memory proof,
        PartialVerifierState memory state
    ) internal view returns (bool) {
        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i = i.uncheckedInc()) {
            lagrange_poly_numbers[i] = i;
        }
        // require(vk.num_inputs > 0); // TODO

        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < vk.num_inputs; i = i.uncheckedInc()) {
            // TODO we may use batched lagrange compputation
            state.t = evaluate_lagrange_poly_out_of_domain(i, vk.domain_size, vk.omega, state.z);
            state.t.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(state.t);
        }
        inputs_term.mul_assign(proof.gate_selectors_openings_at_z[0]);
        PairingsBn254.Fr memory result = proof.linearization_poly_opening_at_z.copy();
        result.add_assign(inputs_term);

        // compute powers of alpha
        compute_powers_of_alpha(state);
        PairingsBn254.Fr memory factor = state.alpha_values[4].copy();
        factor.mul_assign(proof.copy_permutation_grand_product_opening_at_z_omega);

        // - alpha_0 * (a + perm(z) * beta + gamma)*()*(d + gamma) * z(z*omega)
        require(proof.copy_permutation_polys_openings_at_z.length == STATE_WIDTH - 1);
        PairingsBn254.Fr memory t; // TMP;
        for (uint256 i = 0; i < proof.copy_permutation_polys_openings_at_z.length; i = i.uncheckedInc()) {
            t = proof.copy_permutation_polys_openings_at_z[i].copy();
            t.mul_assign(state.beta);
            t.add_assign(proof.state_polys_openings_at_z[i]);
            t.add_assign(state.gamma);

            factor.mul_assign(t);
        }

        t = proof.state_polys_openings_at_z[3].copy();
        t.add_assign(state.gamma);
        factor.mul_assign(t);
        result.sub_assign(factor);

        // - L_0(z) * alpha_1
        PairingsBn254.Fr memory l_0_at_z = evaluate_l0_at_point(vk.domain_size, state.z);
        l_0_at_z.mul_assign(state.alpha_values[4 + 1]);
        result.sub_assign(l_0_at_z);

        PairingsBn254.Fr memory lookup_quotient_contrib = lookup_quotient_contribution(vk, proof, state);
        result.add_assign(lookup_quotient_contrib);

        PairingsBn254.Fr memory lhs = proof.quotient_poly_opening_at_z.copy();
        lhs.mul_assign(evaluate_vanishing(vk.domain_size, state.z));
        return lhs.value == result.value;
    }

    function lookup_quotient_contribution(
        VerificationKey memory vk,
        Proof memory proof,
        PartialVerifierState memory state
    ) internal view returns (PairingsBn254.Fr memory result) {
        PairingsBn254.Fr memory t;

        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        state.beta_plus_one = state.beta_lookup.copy();
        state.beta_plus_one.add_assign(one);
        state.beta_gamma = state.beta_plus_one.copy();
        state.beta_gamma.mul_assign(state.gamma_lookup);

        // (s'*beta + gamma)*(zw')*alpha
        t = proof.lookup_s_poly_opening_at_z_omega.copy();
        t.mul_assign(state.beta_lookup);
        t.add_assign(state.beta_gamma);
        t.mul_assign(proof.lookup_grand_product_opening_at_z_omega);
        t.mul_assign(state.alpha_values[6]);

        // (z - omega^{n-1}) for this part
        PairingsBn254.Fr memory last_omega = vk.omega.pow(vk.domain_size - 1);
        state.z_minus_last_omega = state.z.copy();
        state.z_minus_last_omega.sub_assign(last_omega);
        t.mul_assign(state.z_minus_last_omega);
        result.add_assign(t);

        // - alpha_1 * L_{0}(z)
        state.l_0_at_z = evaluate_lagrange_poly_out_of_domain(0, vk.domain_size, vk.omega, state.z);
        t = state.l_0_at_z.copy();
        t.mul_assign(state.alpha_values[6 + 1]);
        result.sub_assign(t);

        // - alpha_2 * beta_gamma_powered L_{n-1}(z)
        PairingsBn254.Fr memory beta_gamma_powered = state.beta_gamma.pow(vk.domain_size - 1);
        state.l_n_minus_one_at_z = evaluate_lagrange_poly_out_of_domain(
            vk.domain_size - 1,
            vk.domain_size,
            vk.omega,
            state.z
        );
        t = state.l_n_minus_one_at_z.copy();
        t.mul_assign(beta_gamma_powered);
        t.mul_assign(state.alpha_values[6 + 2]);

        result.sub_assign(t);
    }

    function aggregated_linearization_commitment(
        VerificationKey memory vk,
        Proof memory proof,
        PartialVerifierState memory state
    ) internal view returns (PairingsBn254.G1Point memory result) {
        // qMain*(Q_a * A + Q_b * B + Q_c * C + Q_d * D + Q_m * A*B + Q_const + Q_dNext * D_next)
        result = PairingsBn254.new_g1(0, 0);
        // Q_a * A
        PairingsBn254.G1Point memory scaled = vk.gate_setup_commitments[0].point_mul(
            proof.state_polys_openings_at_z[0]
        );
        result.point_add_assign(scaled);
        // Q_b * B
        scaled = vk.gate_setup_commitments[1].point_mul(proof.state_polys_openings_at_z[1]);
        result.point_add_assign(scaled);
        // Q_c * C
        scaled = vk.gate_setup_commitments[2].point_mul(proof.state_polys_openings_at_z[2]);
        result.point_add_assign(scaled);
        // Q_d * D
        scaled = vk.gate_setup_commitments[3].point_mul(proof.state_polys_openings_at_z[3]);
        result.point_add_assign(scaled);
        // Q_m* A*B or Q_ab*A*B
        PairingsBn254.Fr memory t = proof.state_polys_openings_at_z[0].copy();
        t.mul_assign(proof.state_polys_openings_at_z[1]);
        scaled = vk.gate_setup_commitments[4].point_mul(t);
        result.point_add_assign(scaled);
        // Q_AC* A*C
        t = proof.state_polys_openings_at_z[0].copy();
        t.mul_assign(proof.state_polys_openings_at_z[2]);
        scaled = vk.gate_setup_commitments[5].point_mul(t);
        result.point_add_assign(scaled);
        // Q_const
        result.point_add_assign(vk.gate_setup_commitments[6]);
        // Q_dNext * D_next
        scaled = vk.gate_setup_commitments[7].point_mul(proof.state_polys_openings_at_z_omega[0]);
        result.point_add_assign(scaled);
        result.point_mul_assign(proof.gate_selectors_openings_at_z[0]);

        PairingsBn254.G1Point
            memory rescue_custom_gate_linearization_contrib = rescue_custom_gate_linearization_contribution(
                vk,
                proof,
                state
            );
        result.point_add_assign(rescue_custom_gate_linearization_contrib);
        require(vk.non_residues.length == STATE_WIDTH - 1);

        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory factor = state.alpha_values[4].copy();
        for (uint256 i = 0; i < proof.state_polys_openings_at_z.length; ) {
            t = state.z.copy();
            if (i == 0) {
                t.mul_assign(one);
            } else {
                t.mul_assign(vk.non_residues[i - 1]); // TODO add one into non-residues during codegen?
            }
            t.mul_assign(state.beta);
            t.add_assign(state.gamma);
            t.add_assign(proof.state_polys_openings_at_z[i]);

            factor.mul_assign(t);
            unchecked {
                ++i;
            }
        }

        scaled = proof.copy_permutation_grand_product_commitment.point_mul(factor);
        result.point_add_assign(scaled);

        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        factor = state.alpha_values[4].copy();
        factor.mul_assign(state.beta);
        factor.mul_assign(proof.copy_permutation_grand_product_opening_at_z_omega);
        for (uint256 i = 0; i < STATE_WIDTH - 1; i = i.uncheckedInc()) {
            t = proof.copy_permutation_polys_openings_at_z[i].copy();
            t.mul_assign(state.beta);
            t.add_assign(state.gamma);
            t.add_assign(proof.state_polys_openings_at_z[i]);

            factor.mul_assign(t);
        }
        scaled = vk.permutation_commitments[3].point_mul(factor);
        result.point_sub_assign(scaled);

        // + L_0(z) * Z(x)
        // TODO
        state.l_0_at_z = evaluate_lagrange_poly_out_of_domain(0, vk.domain_size, vk.omega, state.z);
        require(state.l_0_at_z.value != 0);
        factor = state.l_0_at_z.copy();
        factor.mul_assign(state.alpha_values[4 + 1]);
        scaled = proof.copy_permutation_grand_product_commitment.point_mul(factor);
        result.point_add_assign(scaled);

        PairingsBn254.G1Point memory lookup_linearization_contrib = lookup_linearization_contribution(proof, state);
        result.point_add_assign(lookup_linearization_contrib);
    }

    function rescue_custom_gate_linearization_contribution(
        VerificationKey memory vk,
        Proof memory proof,
        PartialVerifierState memory state
    ) public view returns (PairingsBn254.G1Point memory result) {
        PairingsBn254.Fr memory t;
        PairingsBn254.Fr memory intermediate_result;

        // a^2 - b = 0
        t = proof.state_polys_openings_at_z[0].copy();
        t.mul_assign(t);
        t.sub_assign(proof.state_polys_openings_at_z[1]);
        // t.mul_assign(challenge1);
        t.mul_assign(state.alpha_values[1]);
        intermediate_result.add_assign(t);

        // b^2 - c = 0
        t = proof.state_polys_openings_at_z[1].copy();
        t.mul_assign(t);
        t.sub_assign(proof.state_polys_openings_at_z[2]);
        t.mul_assign(state.alpha_values[1 + 1]);
        intermediate_result.add_assign(t);

        // c*a - d = 0;
        t = proof.state_polys_openings_at_z[2].copy();
        t.mul_assign(proof.state_polys_openings_at_z[0]);
        t.sub_assign(proof.state_polys_openings_at_z[3]);
        t.mul_assign(state.alpha_values[1 + 2]);
        intermediate_result.add_assign(t);

        result = vk.gate_selectors_commitments[1].point_mul(intermediate_result);
    }

    function lookup_linearization_contribution(Proof memory proof, PartialVerifierState memory state)
        internal
        view
        returns (PairingsBn254.G1Point memory result)
    {
        PairingsBn254.Fr memory zero = PairingsBn254.new_fr(0);

        PairingsBn254.Fr memory t;
        PairingsBn254.Fr memory factor;
        // s(x) from the Z(x*omega)*(\gamma*(1 + \beta) + s(x) + \beta * s(x*omega)))
        factor = proof.lookup_grand_product_opening_at_z_omega.copy();
        factor.mul_assign(state.alpha_values[6]);
        factor.mul_assign(state.z_minus_last_omega);

        PairingsBn254.G1Point memory scaled = proof.lookup_s_poly_commitment.point_mul(factor);
        result.point_add_assign(scaled);

        // Z(x) from - alpha_0 * Z(x) * (\beta + 1) * (\gamma + f(x)) * (\gamma(1 + \beta) + t(x) + \beta * t(x*omega))
        // + alpha_1 * Z(x) * L_{0}(z) + alpha_2 * Z(x) * L_{n-1}(z)

        // accumulate coefficient
        factor = proof.lookup_t_poly_opening_at_z_omega.copy();
        factor.mul_assign(state.beta_lookup);
        factor.add_assign(proof.lookup_t_poly_opening_at_z);
        factor.add_assign(state.beta_gamma);

        // (\gamma + f(x))
        PairingsBn254.Fr memory f_reconstructed;
        PairingsBn254.Fr memory current = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp0;
        for (uint256 i = 0; i < STATE_WIDTH - 1; i = i.uncheckedInc()) {
            tmp0 = proof.state_polys_openings_at_z[i].copy();
            tmp0.mul_assign(current);
            f_reconstructed.add_assign(tmp0);

            current.mul_assign(state.eta);
        }

        // add type of table
        t = proof.lookup_table_type_poly_opening_at_z.copy();
        t.mul_assign(current);
        f_reconstructed.add_assign(t);

        f_reconstructed.mul_assign(proof.lookup_selector_poly_opening_at_z);
        f_reconstructed.add_assign(state.gamma_lookup);

        // end of (\gamma + f(x)) part
        factor.mul_assign(f_reconstructed);
        factor.mul_assign(state.beta_plus_one);
        t = zero.copy();
        t.sub_assign(factor);
        factor = t;
        factor.mul_assign(state.alpha_values[6]);

        // Multiply by (z - omega^{n-1})
        factor.mul_assign(state.z_minus_last_omega);

        // L_{0}(z) in front of Z(x)
        t = state.l_0_at_z.copy();
        t.mul_assign(state.alpha_values[6 + 1]);
        factor.add_assign(t);

        // L_{n-1}(z) in front of Z(x)
        t = state.l_n_minus_one_at_z.copy();
        t.mul_assign(state.alpha_values[6 + 2]);
        factor.add_assign(t);

        scaled = proof.lookup_grand_product_commitment.point_mul(factor);
        result.point_add_assign(scaled);
    }

    struct Queries {
        PairingsBn254.G1Point[13] commitments_at_z;
        PairingsBn254.Fr[13] values_at_z;
        PairingsBn254.G1Point[6] commitments_at_z_omega;
        PairingsBn254.Fr[6] values_at_z_omega;
    }

    function prepare_queries(
        VerificationKey memory vk,
        Proof memory proof,
        PartialVerifierState memory state
    ) public view returns (Queries memory queries) {
        // we set first two items in calee side so start idx from 2
        uint256 idx = 2;
        for (uint256 i = 0; i < STATE_WIDTH; i = i.uncheckedInc()) {
            queries.commitments_at_z[idx] = proof.state_polys_commitments[i];
            queries.values_at_z[idx] = proof.state_polys_openings_at_z[i];
            idx = idx.uncheckedInc();
        }
        require(proof.gate_selectors_openings_at_z.length == 1);
        queries.commitments_at_z[idx] = vk.gate_selectors_commitments[0];
        queries.values_at_z[idx] = proof.gate_selectors_openings_at_z[0];
        idx = idx.uncheckedInc();
        for (uint256 i = 0; i < STATE_WIDTH - 1; i = i.uncheckedInc()) {
            queries.commitments_at_z[idx] = vk.permutation_commitments[i];
            queries.values_at_z[idx] = proof.copy_permutation_polys_openings_at_z[i];
            idx = idx.uncheckedInc();
        }

        queries.commitments_at_z_omega[0] = proof.copy_permutation_grand_product_commitment;
        queries.commitments_at_z_omega[1] = proof.state_polys_commitments[STATE_WIDTH - 1];

        queries.values_at_z_omega[0] = proof.copy_permutation_grand_product_opening_at_z_omega;
        queries.values_at_z_omega[1] = proof.state_polys_openings_at_z_omega[0];

        PairingsBn254.G1Point memory lookup_t_poly_commitment_aggregated = vk.lookup_tables_commitments[0];
        PairingsBn254.Fr memory current_eta = state.eta.copy();
        for (uint256 i = 1; i < vk.lookup_tables_commitments.length; i = i.uncheckedInc()) {
            state.tp = vk.lookup_tables_commitments[i].point_mul(current_eta);
            lookup_t_poly_commitment_aggregated.point_add_assign(state.tp);

            current_eta.mul_assign(state.eta);
        }
        queries.commitments_at_z[idx] = lookup_t_poly_commitment_aggregated;
        queries.values_at_z[idx] = proof.lookup_t_poly_opening_at_z;
        idx = idx.uncheckedInc();
        queries.commitments_at_z[idx] = vk.lookup_selector_commitment;
        queries.values_at_z[idx] = proof.lookup_selector_poly_opening_at_z;
        idx = idx.uncheckedInc();
        queries.commitments_at_z[idx] = vk.lookup_table_type_commitment;
        queries.values_at_z[idx] = proof.lookup_table_type_poly_opening_at_z;
        queries.commitments_at_z_omega[2] = proof.lookup_s_poly_commitment;
        queries.values_at_z_omega[2] = proof.lookup_s_poly_opening_at_z_omega;
        queries.commitments_at_z_omega[3] = proof.lookup_grand_product_commitment;
        queries.values_at_z_omega[3] = proof.lookup_grand_product_opening_at_z_omega;
        queries.commitments_at_z_omega[4] = lookup_t_poly_commitment_aggregated;
        queries.values_at_z_omega[4] = proof.lookup_t_poly_opening_at_z_omega;
    }

    function final_pairing(
        // VerificationKey memory vk,
        PairingsBn254.G2Point[NUM_G2_ELS] memory g2_elements,
        Proof memory proof,
        PartialVerifierState memory state,
        PairingsBn254.G1Point memory aggregated_commitment_at_z,
        PairingsBn254.G1Point memory aggregated_commitment_at_z_omega,
        PairingsBn254.Fr memory aggregated_opening_at_z,
        PairingsBn254.Fr memory aggregated_opening_at_z_omega
    ) internal view returns (bool) {
        // q(x) = f(x) - f(z) / (x - z)
        // q(x) * (x-z)  = f(x) - f(z)

        // f(x)
        PairingsBn254.G1Point memory pair_with_generator = aggregated_commitment_at_z.copy_g1();
        aggregated_commitment_at_z_omega.point_mul_assign(state.u);
        pair_with_generator.point_add_assign(aggregated_commitment_at_z_omega);

        // - f(z)*g
        PairingsBn254.Fr memory aggregated_value = aggregated_opening_at_z_omega.copy();
        aggregated_value.mul_assign(state.u);
        aggregated_value.add_assign(aggregated_opening_at_z);
        PairingsBn254.G1Point memory tp = PairingsBn254.P1().point_mul(aggregated_value);
        pair_with_generator.point_sub_assign(tp);

        // +z * q(x)
        tp = proof.opening_proof_at_z.point_mul(state.z);
        PairingsBn254.Fr memory t = state.z_omega.copy();
        t.mul_assign(state.u);
        PairingsBn254.G1Point memory t1 = proof.opening_proof_at_z_omega.point_mul(t);
        tp.point_add_assign(t1);
        pair_with_generator.point_add_assign(tp);

        // rhs
        PairingsBn254.G1Point memory pair_with_x = proof.opening_proof_at_z_omega.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_proof_at_z);
        pair_with_x.negate();
        // Pairing precompile expects points to be in a `i*x[1] + x[0]` form instead of `x[0] + i*x[1]`
        // so we handle it in code generation step
        PairingsBn254.G2Point memory first_g2 = g2_elements[0];
        PairingsBn254.G2Point memory second_g2 = g2_elements[1];
        PairingsBn254.G2Point memory gen2 = PairingsBn254.P2();

        return PairingsBn254.pairingProd2(pair_with_generator, first_g2, pair_with_x, second_g2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Verifier.sol";
import "../common/interfaces/IAllowList.sol";
import "./libraries/PriorityQueue.sol";

/// @notice Indicates whether an upgrade is initiated and if yes what type
/// @param None Upgrade is NOT initiated
/// @param Transparent Fully transparent upgrade is initiated, upgrade data is publicly known
/// @param Shadow Shadow upgrade is initiated, upgrade data is hidden
enum UpgradeState {
    None,
    Transparent,
    Shadow
}

/// @dev Logically separated part of the storage structure, which is responsible for everything related to proxy upgrades and diamond cuts
/// @param proposedUpgradeHash The hash of the current upgrade proposal, zero if there is no active proposal
/// @param state Indicates whether an upgrade is initiated and if yes what type
/// @param securityCouncil Address which has the permission to approve instant upgrades (expected to be a Gnosis multisig)
/// @param approvedBySecurityCouncil Indicates whether the security council has approved the upgrade
/// @param proposedUpgradeTimestamp The timestamp when the upgrade was proposed, zero if there are no active proposals
/// @param currentProposalId The serial number of proposed upgrades, increments when proposing a new one
struct UpgradeStorage {
    bytes32 proposedUpgradeHash;
    UpgradeState state;
    address securityCouncil;
    bool approvedBySecurityCouncil;
    uint40 proposedUpgradeTimestamp;
    uint40 currentProposalId;
}

/// @dev The log passed from L2
/// @param l2ShardId The shard identifier, 0 - rollup, 1 - porter. All other values are not used but are reserved for the future
/// @param isService A boolean flag that is part of the log along with `key`, `value`, and `sender` address.
/// This field is required formally but does not have any special meaning.
/// @param txNumberInBlock The L2 transaction number in a block, in which the log was sent
/// @param sender The L2 address which sent the log
/// @param key The 32 bytes of information that was sent in the log
/// @param value The 32 bytes of information that was sent in the log
// Both `key` and `value` are arbitrary 32-bytes selected by the log sender
struct L2Log {
    uint8 l2ShardId;
    bool isService;
    uint16 txNumberInBlock;
    address sender;
    bytes32 key;
    bytes32 value;
}

/// @dev An arbitrary length message passed from L2
/// @notice Under the hood it is `L2Log` sent from the special system L2 contract
/// @param txNumberInBlock The L2 transaction number in a block, in which the message was sent
/// @param sender The address of the L2 account from which the message was passed
/// @param data An arbitrary length message
struct L2Message {
    uint16 txNumberInBlock;
    address sender;
    bytes data;
}

/// @notice Part of the configuration parameters of ZKP circuits
struct VerifierParams {
    bytes32 recursionNodeLevelVkHash;
    bytes32 recursionLeafLevelVkHash;
    bytes32 recursionCircuitsSetVksHash;
}

/// @dev storing all storage variables for zkSync facets
/// NOTE: It is used in a proxy, so it is possible to add new variables to the end
/// NOTE: but NOT to modify already existing variables or change their order
/// NOTE: DiamondCutStorage is unused, but it must remain a member of AppStorage to not have storage collision
/// NOTE: instead UpgradeStorage is used that is appended to the end of the AppStorage struct
struct AppStorage {
    /// @dev Storage of variables needed for deprecated diamond cut facet
    uint256[7] __DEPRECATED_diamondCutStorage;
    /// @notice Address which will exercise governance over the network i.e. change validator set, conduct upgrades
    address governor;
    /// @notice Address that the governor proposed as one that will replace it
    address pendingGovernor;
    /// @notice List of permitted validators
    mapping(address => bool) validators;
    /// @dev Verifier contract. Used to verify aggregated proof for blocks
    Verifier verifier;
    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint256 totalBlocksExecuted;
    /// @notice Total number of proved blocks i.e. blocks[totalBlocksProved] points at the latest proved block
    uint256 totalBlocksVerified;
    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint256 totalBlocksCommitted;
    /// @dev Stored hashed StoredBlock for block number
    mapping(uint256 => bytes32) storedBlockHashes;
    /// @dev Stored root hashes of L2 -> L1 logs
    mapping(uint256 => bytes32) l2LogsRootHashes;
    /// @dev Container that stores transactions requested from L1
    PriorityQueue.Queue priorityQueue;
    /// @dev The smart contract that manages the list with permission to call contract functions
    IAllowList allowList;
    /// @notice Part of the configuration parameters of ZKP circuits. Used as an input for the verifier smart contract
    VerifierParams verifierParams;
    /// @notice Bytecode hash of bootloader program.
    /// @dev Used as an input to zkp-circuit.
    bytes32 l2BootloaderBytecodeHash;
    /// @notice Bytecode hash of default account (bytecode for EOA).
    /// @dev Used as an input to zkp-circuit.
    bytes32 l2DefaultAccountBytecodeHash;
    /// @dev Indicates that the porter may be touched on L2 transactions.
    /// @dev Used as an input to zkp-circuit.
    bool zkPorterIsAvailable;
    /// @dev The maximum number of the L2 gas that a user can request for L1 -> L2 transactions
    /// @dev This is the maximum number of L2 gas that is available for the "body" of the transaction, i.e.
    /// without overhead for proving the block.
    uint256 priorityTxMaxGasLimit;
    /// @dev Storage of variables needed for upgrade facet
    UpgradeStorage upgrades;
    /// @dev A mapping L2 block number => message number => flag.
    /// @dev The L2 -> L1 log is sent for every withdrawal, so this mapping is serving as
    /// a flag to indicate that the message was already processed.
    /// @dev Used to indicate that eth withdrawal was already processed
    mapping(uint256 => mapping(uint256 => bool)) isEthWithdrawalFinalized;
    /// @dev The most recent withdrawal time and amount reset
    uint256 lastWithdrawalLimitReset;
    /// @dev The accumulated withdrawn amount during the withdrawal limit window
    uint256 withdrawnAmountInWindow;
    /// @dev A mapping user address => the total deposited amount by the user
    mapping(address => uint256) totalDepositedAmountPerUser;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Plonk4VerifierWithAccessToDNext.sol";
import "../common/libraries/UncheckedMath.sol";

contract Verifier is Plonk4VerifierWithAccessToDNext {
    using UncheckedMath for uint256;

    function get_verification_key() public pure returns (VerificationKey memory vk) {
        vk.num_inputs = 1;
        vk.domain_size = 67108863;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        // coefficients
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x8fa9d6f0dd6ac1cbeb94ae20fe7a23df05cb1095df66fb561190e615a4037ef,
            0x196dcc8692fe322d21375920559944c12ba7b1ba8b732344cf4ba2e3aa0fc8b4
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x74aaf5d97bd57551311a8b3e4aa7840bc55896502020b2f43ad6a98d81a443,
            0x2d275a3ad153dc9d89ebb9c9b6a0afd2dde82470554e9738d905c328fbb4c8bc
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x287f1975a9aeaef5d2bb0767b5ef538f76e82f7da01c0cb6db8c6f920818ec4f,
            0x2fff6f53594129f794a7731d963d27e72f385c5c6d8e08829e6f66a9d29a12ea
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x38809fa3d4b7320d43e023454194f0a7878baa7e73a295d2d105260f1c34cbc,
            0x25418b1105cf45b2a3da6c349bab1d9caaf145eaf24d1e8fb92c11654c000781
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x561cafd527ac3f0bc550db77d87cd1c63938f7ec051e62ebf84a5bbe07f9840,
            0x28f87201b4cbe19f1517a1c29ca6d6cb074502ccfed4c31c8931c6992c3eea43
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x27e0af572bac6e36d31c33808cb44c0ef8ceee5e2850e916fb01f3747db72491,
            0x1da20087ba61c59366b21e31e4ac6889d357cf11bf16b94d875f94f41525c427
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x2c2bcafea8f93d07f96874f470985a8d272c09c8ed49373f36497ee80bd8da17,
            0x299276cf6dca1a7e3780f6276c5d067403f6e024e83e0cc1ab4c5f7252b7f653
        );
        vk.gate_setup_commitments[7] = PairingsBn254.new_g1(
            0xba9d4a53e050da25b8410045b634f1ca065ff74acd35bab1a72bf1f20047ef3,
            0x1f1eefc8b0507a08f852f554bd7abcbd506e52de390ca127477a678d212abfe5
        );
        // gate selectors
        vk.gate_selectors_commitments[0] = PairingsBn254.new_g1(
            0x1c6b68d9920620012d85a4850dad9bd6d03ae8bbc7a08b827199e85dba1ef2b1,
            0xf6380560d1b585628ed259289cec19d3a7c70c60e66bbfebfcb70c8c312d91e
        );
        vk.gate_selectors_commitments[1] = PairingsBn254.new_g1(
            0xdfead780e5067181aae631ff734a33fca302773472997daca58ba49dbd20dcc,
            0xf13fa6e356f525d2fd1c533acf2858c0d2b9f0a9b3180f94e1543929c75073
        );
        // permutation
        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x14da0045925140101816809d965eb7b23f6674023d2b8e9b6d4688b6a68dbd74,
            0x227c0afdb9cc8b35787e418024e278f743ec5d28a918f76e239baab6f1f64d4e
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0xdf5e146c6f5c3e0067f43a5dece2377cb50e490e39cb137b60b470b22e1d56a,
            0x14785150291902282bed97ea25c494e50a3b7ecd227c643ed9fff2f642180318
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x8e4d7500d6c81dc496ceec32a9232d01ace17fd9ae4c66b1c3fa8f16f8935a0,
            0x1ffc8adc78e71c6790fa52b731d3057993fc5b59aa43e74216d5690e0bb7146e
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x21ad7d922e2f67b027cc399603dd3504c2c6c5c419cec98d22fca608b6a740eb,
            0xfe14421b9a57c612073f3c2c1eb48a1c6168e250bcabc9cbd89399be35a8347
        );
        // lookup selector commitment
        vk.lookup_selector_commitment = PairingsBn254.new_g1(
            0x2f491c662ae53ceb358f57a868dc00b89befa853bd9a449127ea2d46820995bd,
            0x231fe6538634ff8b6fa21ca248fb15e7f43d82eb0bfa705490d24ddb3e3cad77
        );
        // lookup table commitments
        vk.lookup_tables_commitments[0] = PairingsBn254.new_g1(
            0xebe0de4a2f39df3b903da484c1641ffdffb77ff87ce4f9508c548659eb22d3c,
            0x12a3209440242d5662729558f1017ed9dcc08fe49a99554dd45f5f15da5e4e0b
        );
        vk.lookup_tables_commitments[1] = PairingsBn254.new_g1(
            0x1b7d54f8065ca63bed0bfbb9280a1011b886d07e0c0a26a66ecc96af68c53bf9,
            0x2c51121fff5b8f58c302f03c74e0cb176ae5a1d1730dec4696eb9cce3fe284ca
        );
        vk.lookup_tables_commitments[2] = PairingsBn254.new_g1(
            0x138733c5faa9db6d4b8df9748081e38405999e511fb22d40f77cf3aef293c44,
            0x269bee1c1ac28053238f7fe789f1ea2e481742d6d16ae78ed81e87c254af0765
        );
        vk.lookup_tables_commitments[3] = PairingsBn254.new_g1(
            0x1b1be7279d59445065a95f01f16686adfa798ec4f1e6845ffcec9b837e88372e,
            0x57c90cb96d8259238ed86b05f629efd55f472a721efeeb56926e979433e6c0e
        );
        // table type commitment
        vk.lookup_table_type_commitment = PairingsBn254.new_g1(
            0x12cd873a6f18a4a590a846d9ebf61565197edf457efd26bc408eb61b72f37b59,
            0x19890cbdac892682e7a5910ca6c238c082130e1c71f33d0c9c901153377770d1
        );
        // non residues
        vk.non_residues[0] = PairingsBn254.new_fr(0x5);
        vk.non_residues[1] = PairingsBn254.new_fr(0x7);
        vk.non_residues[2] = PairingsBn254.new_fr(0xa);
        // g2 elements
        vk.g2_elements[0] = PairingsBn254.new_g2(
            [
                0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
                0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
        vk.g2_elements[1] = PairingsBn254.new_g2(
            [
                0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
                0x118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0
            ],
            [
                0x4fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
                0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55
            ]
        );
    }

    function deserialize_proof(uint256[] calldata public_inputs, uint256[] calldata serialized_proof)
        internal
        pure
        returns (Proof memory proof)
    {
        // require(serialized_proof.length == 44); TODO
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i = i.uncheckedInc()) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j;
        for (uint256 i = 0; i < STATE_WIDTH; i = i.uncheckedInc()) {
            proof.state_polys_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j.uncheckedInc()]
            );

            j = j.uncheckedAdd(2);
        }
        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);

        proof.lookup_s_poly_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);

        proof.lookup_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);
        for (uint256 i = 0; i < proof.quotient_poly_parts_commitments.length; i = i.uncheckedInc()) {
            proof.quotient_poly_parts_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j.uncheckedInc()]
            );
            j = j.uncheckedAdd(2);
        }

        for (uint256 i = 0; i < proof.state_polys_openings_at_z.length; i = i.uncheckedInc()) {
            proof.state_polys_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }

        for (uint256 i = 0; i < proof.state_polys_openings_at_z_omega.length; i = i.uncheckedInc()) {
            proof.state_polys_openings_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        for (uint256 i = 0; i < proof.gate_selectors_openings_at_z.length; i = i.uncheckedInc()) {
            proof.gate_selectors_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        for (uint256 i = 0; i < proof.copy_permutation_polys_openings_at_z.length; i = i.uncheckedInc()) {
            proof.copy_permutation_polys_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        proof.copy_permutation_grand_product_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_s_poly_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_grand_product_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_t_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_t_poly_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_selector_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_table_type_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.quotient_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.linearization_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.opening_proof_at_z = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);
        proof.opening_proof_at_z_omega = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
    }

    function verify_serialized_proof(uint256[] calldata public_inputs, uint256[] calldata serialized_proof)
        public
        view
        returns (bool)
    {
        VerificationKey memory vk = get_verification_key();
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        return verify(proof, vk);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Matter Labs
interface IL2Bridge {
    event FinalizeDeposit(
        address indexed l1Sender,
        address indexed l2Receiver,
        address indexed l2Token,
        uint256 amount
    );

    event WithdrawalInitiated(
        address indexed l2Sender,
        address indexed l1Receiver,
        address indexed l2Token,
        uint256 amount
    );

    function finalizeDeposit(
        address _l1Sender,
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function withdraw(
        address _l1Receiver,
        address _l2Token,
        uint256 _amount
    ) external;

    function l1TokenAddress(address _l2Token) external view returns (address);

    function l2TokenAddress(address _l1Token) external view returns (address);

    function l1Bridge() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import "@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IMailbox.sol";
import "@matterlabs/zksync-contracts/l1/contracts/bridge/interfaces/IL1Bridge.sol";
import "@matterlabs/zksync-contracts/l2/contracts/bridge/interfaces/IL2Bridge.sol";

interface TokenLike {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

// Managed locked funds in L1Escrow and send / receive messages to L2DAITokenBridge counterpart
// Note: when bridge is closed it will still process in progress messages

contract L1DAITokenBridge is IL1Bridge {
  // --- Auth ---
  mapping(address => uint256) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "L1DAITokenBridge/not-authorized");
    _;
  }

  address constant BOOTLOADER_ADDRESS = 0x0000000000000000000000000000000000008001; // address(SYSTEM_CONTRACTS_OFFSET + 0x01);

  // prettier-ignore
  address public immutable l1Token; // the address of L1 Dai
  address public immutable l2Bridge; // the counterpart bridge contract on L2
  address public immutable l2Token; // the address of L2 Dai
  address public immutable escrow; // contract holding all deposited L1 Dai
  IMailbox public immutable zkSyncMailbox; // zkSync main contract on L1
  uint256 public isOpen = 1; // flag indicating if the bridge is open to deposits

  mapping(uint256 => mapping(uint256 => bool)) public isWithdrawalFinalized; // flag used to mark a pending withdrawal as finalized and prevent it from being double-spent
  mapping(address => mapping(bytes32 => uint256)) public depositAmount; // the amount of Dai deposited for a given depositer and L2 transaction hash (used for deposit cancellation).

  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event File(bytes32 indexed what, uint256 data);
  event Closed();

  constructor(
    address _l1Token,
    address _l2Bridge,
    address _l2Token,
    address _escrow,
    IMailbox _mailbox
  ) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l1Token = _l1Token;
    l2Bridge = _l2Bridge;
    l2Token = _l2Token;
    escrow = _escrow;
    zkSyncMailbox = _mailbox;
  }

  /**
   * @notice Returns the L2 Dai token address. This is not used by this contract but is included here so that
   * this contract fully implements the IL1Bridge interface used by zkSync standard token bridge (L1ERC20Bridge).
   */
  function l2TokenAddress(address _l1Token) external view returns (address) {
    require(_l1Token == l1Token, "L1DAITokenBridge/token-not-dai");
    return l2Token;
  }

  /**
   * @notice Close the L1 side of the bridge, preventing future deposits
   */
  function close() external auth {
    isOpen = 0;

    emit Closed();
  }

  /**
   * @notice Deposit Dai from Ethereum L1 to zkSync L2
   * @param _l2Receiver The recipient address on L2
   * @param _l1Token The address of the Dai token on L1
   * @param _amount The amount of Dai to deposit (in WAD)
   * @param _l2TxGasLimit The L2 gas limit to be used in the corresponding L2 transaction
   * @param _l2TxGasPerPubdataByte The gasPerPubdataByteLimit to be used in the corresponding L2 transaction
   */
  function deposit(
    address _l2Receiver,
    address _l1Token,
    uint256 _amount,
    uint256 _l2TxGasLimit,
    uint256 _l2TxGasPerPubdataByte
  ) external payable returns (bytes32 txHash) {
    require(_l1Token == l1Token, "L1DAITokenBridge/token-not-dai");
    require(isOpen == 1, "L1DAITokenBridge/closed");

    TokenLike(l1Token).transferFrom(msg.sender, escrow, _amount);

    bytes memory l2TxCalldata = abi.encodeWithSelector(
      IL2Bridge.finalizeDeposit.selector,
      msg.sender,
      _l2Receiver,
      _l1Token,
      _amount,
      "" // _data is not used in this bridge but still kept as an argument of finalizeDeposit for consistency with ZkSync's standard ERC20 bridge
    );

    txHash = zkSyncMailbox.requestL2Transaction{value: msg.value}(
      l2Bridge,
      0, // l2Value is the amount of ETH sent to the L2 method. As the L2 method is non-payable, this is always 0
      l2TxCalldata,
      _l2TxGasLimit,
      _l2TxGasPerPubdataByte,
      new bytes[](0), // array of L2 bytecodes that will be marked as known on L2. This is only required when deploying an L2 contract, so is left empty here
      msg.sender // The address on L2 that will receive the refund for the transaction
    );

    depositAmount[msg.sender][txHash] = _amount;

    emit DepositInitiated(msg.sender, _l2Receiver, _l1Token, _amount);
  }

  /**
   * @notice Recover the L1 Dai sent to the escrow when the L1 > L2 deposit message failed to
   * be executed on L2 (for example because of the amount of ETH sent with the deposit transaction was not
   * large enough to cover the cost of the L2 transaction).
   * @param _depositSender The address of the account that sent the L1 Dai
   * @param _l1Token The address of the Dai token on L1
   * @param _l2TxHash The transaction hash of the failed L2 transaction
   * @param _l1BatchNumber The number of the L1 batch that includes the failed L2 transaction
   * @param _l2MessageIndex The position of the L2 log (corresponding to the failed L2 transaction) in the L2 logs Merkle tree
   * @param _l1BatchTxIndex The position of the failed L2 transaction in the L1 batch
   * @param _merkleProof Merkle proof of inclusion of the L2 log (corresponding to the failed L2 transaction)
   */
  function claimFailedDeposit(
    address _depositSender,
    address _l1Token,
    bytes32 _l2TxHash,
    uint256 _l1BatchNumber,
    uint256 _l2MessageIndex,
    uint16 _l1BatchTxIndex,
    bytes32[] calldata _merkleProof
  ) external {
    require(_l1Token == l1Token, "L1DAITokenBridge/token-not-dai");

    L2Log memory l2Log = L2Log({
      l2ShardId: 0, // the shard identifier, 0 - rollup, 1 - porter.
      isService: true, // boolean flag that is part of the log along with `key`, `value`, and `sender` address. This field is required formally but does not have any special meaning.
      txNumberInBlock: _l1BatchTxIndex,
      sender: BOOTLOADER_ADDRESS, // the L2 address which sent the log
      key: _l2TxHash,
      value: bytes32(0) // a zero value indicates a failed L2 transaction
    });
    bool success = zkSyncMailbox.proveL2LogInclusion(
      _l1BatchNumber,
      _l2MessageIndex,
      l2Log,
      _merkleProof
    );
    require(success, "L1DAITokenBridge/wrong-proof");

    uint256 amount = depositAmount[_depositSender][_l2TxHash];
    require(amount > 0, "L1DAITokenBridge/not-deposited");

    depositAmount[_depositSender][_l2TxHash] = 0;
    TokenLike(l1Token).transferFrom(escrow, _depositSender, amount);

    emit ClaimedFailedDeposit(_depositSender, _l1Token, amount);
  }

  /**
   * @notice Finalize an L2 > L1 Dai withdrawal
   * @param _l1BatchNumber The number of the L1 batch that includes the withdrawal transaction on L2
   * @param _l2MessageIndex The position of the L2 log (corresponding to the withdrawal transaction on L2) in the L2 logs Merkle tree
   * @param _l1BatchTxIndex The position of the withdrawal L2 transaction in the L1 batch
   * @param _message The withdrawal message encoded as `abi.encodePacked(IL1Bridge.finalizeWithdrawal.selector, _to, _amount)`
   * @param _merkleProof Merkle proof of inclusion of the L2 log (corresponding to the withdrawal transaction on L2)
   */
  function finalizeWithdrawal(
    uint256 _l1BatchNumber,
    uint256 _l2MessageIndex,
    uint16 _l1BatchTxIndex,
    bytes calldata _message,
    bytes32[] calldata _merkleProof
  ) external {
    require(
      !isWithdrawalFinalized[_l1BatchNumber][_l2MessageIndex],
      "L1DAITokenBridge/was-withdrawn"
    );
    L2Message memory l2ToL1Message = L2Message({
      txNumberInBlock: _l1BatchTxIndex,
      sender: l2Bridge,
      data: _message
    });

    (address l1Receiver, uint256 amount) = _parseL2WithdrawalMessage(l2ToL1Message.data);
    bool success = zkSyncMailbox.proveL2MessageInclusion(
      _l1BatchNumber,
      _l2MessageIndex,
      l2ToL1Message,
      _merkleProof
    );
    require(success, "L1DAITokenBridge/invalid-proof");

    isWithdrawalFinalized[_l1BatchNumber][_l2MessageIndex] = true;

    TokenLike(l1Token).transferFrom(escrow, l1Receiver, amount);

    emit WithdrawalFinalized(l1Receiver, l1Token, amount);
  }

  function _parseL2WithdrawalMessage(
    bytes memory _l2ToL1message
  ) internal pure returns (address l1Receiver, uint256 amount) {
    // _l2ToL1message = {size:32}{funSig:4}{l1Receiver:20}{amount:32} => _l2ToL1message.length = 4 + 20 + 32 = 56 (bytes).
    require(_l2ToL1message.length == 56, "L1DAITokenBridge/bad-msg-length");

    uint32 funSig;
    assembly {
      funSig := mload(add(_l2ToL1message, 4))
    }
    require(bytes4(funSig) == this.finalizeWithdrawal.selector, "L1DAITokenBridge/bad-msg-sig");

    assembly {
      l1Receiver := mload(add(_l2ToL1message, 24))
      amount := mload(add(_l2ToL1message, 56))
    }
  }
}