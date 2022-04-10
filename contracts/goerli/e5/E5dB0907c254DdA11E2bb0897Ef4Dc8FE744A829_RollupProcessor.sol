// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import {IVerifier} from './interfaces/IVerifier.sol';
import {IRollupProcessor} from './interfaces/IRollupProcessor.sol';
import {IFeeDistributor} from './interfaces/IFeeDistributor.sol';
import {IERC20Permit} from './interfaces/IERC20Permit.sol';
import {IDefiBridge} from './interfaces/IDefiBridge.sol';

import {Decoder} from './Decoder.sol';
import {AztecTypes} from './AztecTypes.sol';

import {TokenTransfers} from './libraries/TokenTransfers.sol';
import './libraries/RollupProcessorLibrary.sol';

/**
 * @title Rollup Processor
 * @dev Smart contract responsible for processing Aztec zkRollups, including relaying them to a verifier
 * contract for validation and performing all relevant ERC20 token transfers
 */
contract RollupProcessor is IRollupProcessor, Decoder, Initializable, OwnableUpgradeable, PausableUpgradeable {
    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error REENTRANCY_MUTEX_SET();
    error INVALID_ASSET_ID();
    error INVALID_ASSET_ADDRESS();
    error PROOF_VERIFICATION_FAILED();
    error INCORRECT_STATE_HASH(bytes32 oldStateHash, bytes32 newStateHash);
    error INCORRECT_DATA_START_INDEX(uint256 providedIndex, uint256 expectedIndex);
    error BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(uint256 outputAssetId);
    error BRIDGE_ID_IS_INCONSISTENT();
    error INCORRECT_PREVIOUS_DEFI_INTERACTION_HASH(
        bytes32 providedDefiInteractionHash,
        bytes32 expectedDefiInteractionHash
    );
    error ZERO_TOTAL_INPUT_VALUE();
    error ARRAY_OVERFLOW();
    error ZERO_BRIDGE_ADDRESS_ID();
    error ASYNC_CALLBACK_BAD_CALLER_ADDRESS();
    error MSG_VALUE_WRONG_AMOUNT();
    error TOKEN_TRANSFER_FAILED();
    error INSUFFICIENT_ETH_TRANSFER();
    error WITHDRAW_TO_ZERO_ADDRESS();
    error INVALID_DEPOSITOR();
    error INSUFFICIENT_DEPOSIT();
    error INVALID_LINKED_TOKEN_ADDRESS();
    error INVALID_LINKED_BRIDGE_ADDRESS();
    error TOKEN_ASSET_IS_NOT_LINKED();
    error DEPOSIT_TOKENS_WRONG_PAYMENT_TYPE();
    error INSUFFICIENT_TOKEN_APPROVAL();
    error INVALID_PROVIDER();
    error INVALID_BRIDGE_ID();
    error INVALID_BRIDGE_ADDRESS();
    error NONZERO_OUTPUT_VALUE_ON_NOT_USED_ASSET(uint256 outputValue);
    error PUBLIC_INPUTS_HASH_VERIFICATION_FAILED(uint256, uint256);
    error THIRD_PARTY_CONTRACTS_FLAG_NOT_SET();

    /*----------------------------------------
      FUNCTION SELECTORS (PRECOMPUTED)
      ----------------------------------------*/
    // DEFI_BRIDGE_PROXY_CONVERT_SELECTOR = function signature of:
    //   function convert(
    //       address,
    //       AztecTypes.AztecAsset memory inputAssetA,
    //       AztecTypes.AztecAsset memory inputAssetB,
    //       AztecTypes.AztecAsset memory outputAssetA,
    //       AztecTypes.AztecAsset memory outputAssetB,
    //       uint256 totalInputValue,
    //       uint256 interactionNonce,
    //       uint256 auxData,
    //       uint256 ethPaymentsSlot
    //       address rollupBeneficary)
    // N.B. this is the selector of the 'convert' function of the DefiBridgeProxy contract.
    //      This has a different interface to the IDefiBridge.convert function
    bytes4 private constant DEFI_BRIDGE_PROXY_CONVERT_SELECTOR = 0x4bd947a8;

    /*----------------------------------------
      CONSTANT STATE VARIABLES
      ----------------------------------------*/

    uint256 private constant ethAssetId = 0; // if assetId == ethAssetId, treat as native ETH and not ERC20 token
    bool public allowThirdPartyContracts;

    // starting root hash of the DeFi interaction result Merkle tree
    bytes32 private constant INIT_DEFI_ROOT = 0x2e4ab7889ab3139204945f9e722c7a8fdb84e66439d787bd066c3d896dba04ea;

    bytes32 private constant DEFI_BRIDGE_PROCESSED_SIGHASH =
        0x1ccb5390975e3d07503983a09c3b6a5d11a0e40c4cb4094a7187655f643ef7b4;

    bytes32 private constant ASYNC_BRIDGE_PROCESSED_SIGHASH =
        0x38ce48f4c2f3454bcf130721f25a4262b2ff2c8e36af937b30edf01ba481eb1d;

    // We need to cap the amount of gas sent to the DeFi bridge contract for two reasons.
    // 1: To provide consistency to rollup providers around costs.
    // 2: To prevent griefing attacks where a bridge consumes all our gas.
    uint256 private constant MIN_BRIDGE_GAS_LIMIT = 35000;
    uint256 private constant MIN_ERC20_GAS_LIMIT = 55000;
    uint256 private constant MAX_BRIDGE_GAS_LIMIT = 5000000;
    uint256 private constant MAX_ERC20_GAS_LIMIT = 1500000;

    // Bit offsets and bit masks used to convert a `uint256 bridgeId` into a BridgeData member
    uint256 private constant INPUT_ASSET_ID_A_SHIFT = 32;
    uint256 private constant OUTPUT_ASSET_ID_A_SHIFT = 62;
    uint256 private constant OUTPUT_ASSET_ID_B_SHIFT = 92;
    uint256 private constant INPUT_ASSET_ID_B_SHIFT = 122;
    uint256 private constant BITCONFIG_SHIFT = 152;
    uint256 private constant AUX_DATA_SHIFT = 184;
    uint256 private constant MASK_THIRTY_TWO_BITS = 0xffffffff;
    uint256 private constant MASK_THIRTY_BITS = 0x3fffffff;
    uint256 private constant MASK_SIXTY_FOUR_BITS = 0xffffffffffffffff;

    // Offsets and masks used to encode/decode the stateHash storage variable of RollupProcessor
    uint256 private constant DATASIZE_BIT_OFFSET = 160;
    uint256 private constant ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET = 192;
    uint256 private constant DEFIINTERACTIONHASHES_BIT_OFFSET = 208;
    uint256 private constant REENTRANCY_MUTEX_BIT_OFFSET = 224;
    uint256 private constant ARRAY_LENGTH_MASK = 0x3ff; // 1023
    uint256 private constant DATASIZE_MASK = 0xffffffff;

    /*----------------------------------------
      PRIVATE/INTERNAL STATE VARIABLES
      ----------------------------------------*/
    // asyncDefiInteractionHashes and defiInteractionHashes are custom implementations of an array type!!
    // we store the length fields for each array inside the `rollupState` storage slot
    // we access array elements in the traditional manner: array.slot[i] = keccak256(array.slot + i)
    // however we do NOT use slot to recover the length of the array (e.g. normally this would be `length := sload(array.slot)`
    // this reduces the number of storage slots we write to when processing a rollup
    // (each slot costs 5,000 gas to update, saves us 10k gas per rollup tx)
    bytes32 internal asyncDefiInteractionHashes; // defi interaction hashes to be transferred into pending defi interaction hashes
    bytes32 internal defiInteractionHashes;

    // Mapping from assetId to mapping of userAddress to public userBalance stored on this contract
    mapping(uint256 => mapping(address => uint256)) internal userPendingDeposits;

    mapping(address => mapping(bytes32 => bool)) public depositProofApprovals;

    /**
     * @dev RollupState struct contains the following data (offsets are for when used as storage slot):
     *
     * | bit offset   | num bits    | description |
     * | ---          | ---         | ---         |
     * | 0            | 160         | PLONK verifier contract address |
     * | 160          | 32          | datasize: number of filled entries in note tree |
     * | 192          | 16          | asyncDefiInteractionHashes.length : number of entries in asyncDefiInteractionHashes array |
     * | 208          | 16          | defiInteractionHashes.length : number of entries in defiInteractionHashes array |
     * | 224          | 1           | reentrancyMutex used to guard against reentrancy attacks
     */
    struct RollupState {
        IVerifier verifier;
        uint32 datasize;
        uint16 numAsyncDefiInteractionHashes;
        uint16 numDefiInteractionHashes;
        bool reentrancyMutex;
    }
    RollupState internal rollupState;

    /*----------------------------------------
      PUBLIC STATE VARIABLES
      ----------------------------------------*/
    bytes32 public rollupStateHash;

    address public override defiBridgeProxy;

    uint256 public escapeBlockLowerBound;
    uint256 public escapeBlockUpperBound;

    // Array of supported ERC20 token address.
    address[] public supportedAssets;

    // Array of supported bridge contract addresses (similar to assetIds)
    address[] public supportedBridges;

    mapping(address => bool) public rollupProviders;

    // we need a way to register ERC20 Gas Limits for withdrawals to a specific asset id
    mapping(uint256 => uint256) public assetGasLimit;

    // map defiInteractionNonce to PendingDefiBridgeInteraction
    mapping(uint256 => PendingDefiBridgeInteraction) public pendingDefiInteractions;

    /**
     * @dev Used by brige contracts to send RollupProcessor ETH during a bridge interaction
     */
    mapping(uint256 => uint256) public ethPayments;

    // we need a way to register ERC20 Gas Limits for withdrawals to a specific asset id
    mapping(uint256 => uint256) public assetGasLimits;

    // we need a way to register Bridge Gas Limits for dynamic limits per DeFi protocol
    mapping(uint256 => uint256) public bridgeGasLimits;

    // stores the hash of the hashes of the pending defi interactions, the notes of which are expected to be added in the 'next' rollup
    bytes32 public prevDefiInteractionsHash;

    // the value of hashing a 'zeroed' defi interaction result
    bytes32 private constant DEFI_RESULT_ZERO_HASH = 0x2d25a1e3a51eb293004c4b56abe12ed0da6bca2b4a21936752a85d102593c1b4;

    /*----------------------------------------
      EVENTS
      ----------------------------------------*/
    event OffchainData(uint256 indexed rollupId, address sender);
    event RollupProcessed(uint256 indexed rollupId, bytes32[] nextExpectedDefiHashes, address sender);
    event DefiBridgeProcessed(
        uint256 indexed bridgeId,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result
    );
    event AsyncDefiBridgeProcessed(uint256 indexed bridgeId, uint256 indexed nonce, uint256 totalInputValue);
    event Deposit(uint256 assetId, address depositorAddress, uint256 depositValue);
    event Withdraw(uint256 assetId, address withdrawAddress, uint256 withdrawValue);
    event WithdrawError(bytes errorReason);
    event AssetAdded(uint256 indexed assetId, address indexed assetAddress, uint256 assetGasLimit);
    event BridgeAdded(uint256 indexed bridgeAddressId, address indexed bridgeAddress, uint256 bridgeGasLimit);
    event RollupProviderUpdated(address indexed providerAddress, bool valid);
    event VerifierUpdated(address indexed verifierAddress);

    /*----------------------------------------
      STRUCTS
      ----------------------------------------*/
    /**
     * @dev Contains information that describes a specific DeFi bridge
     * @notice A single smart contract can be used to represent multiple bridges
     *
     * @param bridgeAddressId the bridge contract address = supportedBridges[bridgeAddressId]
     * @param bridgeAddress   the bridge contract address
     * @param inputAssetIdA
     */
    struct BridgeData {
        uint256 bridgeAddressId;
        address bridgeAddress;
        uint256 inputAssetIdA;
        uint256 outputAssetIdA;
        uint256 outputAssetIdB;
        uint256 inputAssetIdB;
        uint256 auxData;
        bool firstInputVirtual;
        bool secondInputVirtual;
        bool firstOutputVirtual;
        bool secondOutputVirtual;
        bool secondInputReal;
        bool secondOutputReal;
        uint256 bridgeGasLimit;
    }

    /**
     * @dev Represents an asynchronous defi bridge interaction that has not been resolved
     * @param bridgeId the bridge id
     * @param totalInputValue number of tokens/wei sent to the bridge
     */
    struct PendingDefiBridgeInteraction {
        uint256 bridgeId;
        uint256 totalInputValue;
    }

    /**
     * @dev Container for the results of a DeFi interaction
     * @param outputValueA number of returned tokens for the interaction's first output asset
     * @param outputValueB number of returned tokens for the interaction's second output asset (if relevant)
     * @param isAsync is the interaction asynchronous? i.e. triggering an interaction does not immediately resolve
     * @param success did the call to the bridge succeed or fail?
     *
     * @notice async interactions must have outputValueA == 0 and outputValueB == 0 (tokens get returned later via calling `processAsyncDefiInteraction`)
     */
    struct BridgeResult {
        uint256 outputValueA;
        uint256 outputValueB;
        bool isAsync;
        bool success;
    }

    /**
     * @dev Container for the inputs of a Defi interaction
     * @param totalInputValue number of tokens/wei sent to the bridge
     * @param interactionNonce the unique id of the interaction
     * @param auxData additional input specific to the type of interaction
     */
    struct InteractionInputs {
        uint256 totalInputValue;
        uint256 interactionNonce;
        uint64 auxData;
    }

    /*----------------------------------------
      FUNCTIONS
      ----------------------------------------*/

    /**
     * @dev get the number of filled entries in the data tree.
     * This is equivalent to the number of notes created in the Aztec L2
     * @return dataSize
     */
    function getDataSize() public view returns (uint256 dataSize) {
        assembly {
            dataSize := and(DATASIZE_MASK, shr(DATASIZE_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev get the value of the reentrancy mutex
     */
    function getReentrancyMutex() internal view returns (bool mutexValue) {
        assembly {
            mutexValue := shr(REENTRANCY_MUTEX_BIT_OFFSET, sload(rollupState.slot))
        }
    }

    /**
     * @dev set the reentrancy mutex to true
     */
    function setReentrancyMutex() internal {
        assembly {
            let oldState := sload(rollupState.slot)
            let updatedState := or(shl(REENTRANCY_MUTEX_BIT_OFFSET, 1), oldState)
            sstore(rollupState.slot, updatedState)
        }
    }

    /**
     * @dev clear the reentrancy mutex
     */
    function clearReentrancyMutex() internal {
        assembly {
            let oldState := sload(rollupState.slot)
            let updatedState := and(not(shl(REENTRANCY_MUTEX_BIT_OFFSET, 1)), oldState)
            sstore(rollupState.slot, updatedState)
        }
    }

    /**
     * @dev validate the reentrancy mutex is not set. Throw if it is
     */
    function reentrancyMutexCheck() internal view {
        bool mutexValue;
        assembly {
            mutexValue := shr(REENTRANCY_MUTEX_BIT_OFFSET, sload(rollupState.slot))
        }
        if (mutexValue) {
            revert REENTRANCY_MUTEX_SET();
        }
    }

    /**
     * @dev Get number of defi interaction hashes
     * A defi interaction hash represents a synchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the number of pending defi interaction hashes
     */
    function getDefiInteractionHashesLength() internal view returns (uint256 res) {
        assembly {
            res := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev Get number of asynchronous defi interaction hashes
     * An async defi interaction hash represents an asynchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the number of pending async defi interaction hashes
     */
    function getAsyncDefiInteractionHashesLength() internal view returns (uint256 res) {
        assembly {
            res := and(ARRAY_LENGTH_MASK, shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, sload(rollupState.slot)))
        }
    }

    /**
     * @dev Get all pending defi interaction hashes
     * A defi interaction hash represents a synchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the set of all pending defi interaction hashes
     */
    function getDefiInteractionHashes() external view returns (bytes32[] memory res) {
        uint256 len = getDefiInteractionHashesLength();
        assembly {
            mstore(0x00, defiInteractionHashes.slot)
            let slot := keccak256(0x00, 0x20)
            res := mload(0x40)
            mstore(0x40, add(res, add(0x20, mul(len, 0x20))))
            mstore(res, len)
            let ptr := add(res, 0x20)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x01)
            } {
                mstore(ptr, sload(add(slot, i)))
                ptr := add(ptr, 0x20)
            }
        }
        return res;
    }

    /**
     * @dev Get all pending async defi interaction hashes
     * An async defi interaction hash represents an asynchronous defi interaction that has resolved, but whose interaction result data
     * has not yet been added into the Aztec Defi Merkle tree. This step is needed in order to convert L2 Defi claim notes into L2 value notes
     * @return res the set of all pending async defi interaction hashes
     */
    function getAsyncDefiInteractionHashes() external view returns (bytes32[] memory res) {
        uint256 len = getAsyncDefiInteractionHashesLength();
        assembly {
            mstore(0x00, asyncDefiInteractionHashes.slot)
            let slot := keccak256(0x00, 0x20)
            res := mload(0x40)
            mstore(0x40, add(res, add(0x20, mul(len, 0x20))))
            mstore(res, len)
            let ptr := add(res, 0x20)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x01)
            } {
                mstore(ptr, sload(add(slot, i)))
                ptr := add(ptr, 0x20)
            }
        }
        return res;
    }

    /**
     * @dev Get number of pending defi interactions that have resolved but have not yet added into the Defi Tree
     * This value can never exceed 512. This is to prevent griefing attacks; `processRollup` iterates through `asyncDefiInteractionHashes[]` and
     * copies their values into `defiInteractionHashes[]`. Loop is bounded to < 512 so that tx does not exceed block gas limit
     * @return res the number of pending interactions
     */
    function getPendingDefiInteractionHashes() public view returns (uint256 res) {
        assembly {
            let state := sload(rollupState.slot)
            let defiInteractionHashesLength := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))
            let asyncDefiInteractionhashesLength := and(
                ARRAY_LENGTH_MASK,
                shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state)
            )
            res := add(defiInteractionHashesLength, asyncDefiInteractionhashesLength)
        }
    }

    /**
     * @dev Initialiser function. Emulates constructor behaviour for upgradeable contracts
     * @param _verifierAddress the address of the Plonk verification smart contract
     * @param _escapeBlockLowerBound defines start of escape hatch window
     * @param _escapeBlockUpperBound defines end of the escape hatch window
     * @param _defiBridgeProxy address of the proxy contract that we route defi bridge calls through via `delegateCall`
     * @param _contractOwner owner address of RollupProcessor. Should be a multisig contract
     * @param _initDataRoot starting state of the Aztec data tree. Init tree state should be all-zeroes excluding migrated account notes
     * @param _initNullRoot starting state of the Aztec nullifier tree. Init tree state should be all-zeroes excluding migrated account nullifiers
     * @param _initRootRoot starting state of the Aztec data roots tree. Init tree state should be all-zeroes excluding 1 leaf containing _initDataRoot
     * @param _initDatasize starting size of the Aztec data tree.
     * @param _allowThirdPartyContracts flag that specifies whether 3rd parties are allowed to add state to the contract
     */
    function initialize(
        address _verifierAddress,
        uint256 _escapeBlockLowerBound,
        uint256 _escapeBlockUpperBound,
        address _defiBridgeProxy,
        address _contractOwner,
        bytes32 _initDataRoot,
        bytes32 _initNullRoot,
        bytes32 _initRootRoot,
        uint32 _initDatasize,
        bool _allowThirdPartyContracts
    ) external initializer {
        __Ownable_init();
        transferOwnership(_contractOwner);
        __Pausable_init();
        // compute rollupStateHash
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0) // nextRollupId
            mstore(add(mPtr, 0x20), _initDataRoot)
            mstore(add(mPtr, 0x40), _initNullRoot)
            mstore(add(mPtr, 0x60), _initRootRoot)
            mstore(add(mPtr, 0x80), INIT_DEFI_ROOT)
            sstore(rollupStateHash.slot, keccak256(mPtr, 0xa0))
        }
        rollupState.datasize = _initDatasize;
        rollupState.verifier = IVerifier(_verifierAddress);
        defiBridgeProxy = _defiBridgeProxy;
        escapeBlockLowerBound = _escapeBlockLowerBound;
        escapeBlockUpperBound = _escapeBlockUpperBound;
        allowThirdPartyContracts = _allowThirdPartyContracts;
        // initial value of the hash of 32 'zero' defi note hashes
        prevDefiInteractionsHash = 0x14e0f351ade4ba10438e9b15f66ab2e6389eea5ae870d6e8b2df1418b2e6fd5b;
    }

    /**
     * @dev Allow the multisig owner to pause the contract, in case of bugs.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @dev Used by bridge contracts to send RollupProcessor ETH during a bridge interaction
     * @param interactionNonce the Defi interaction nonce that this payment is logged against
     */
    function receiveEthFromBridge(uint256 interactionNonce) external payable {
        assembly {
            // ethPayments[interactionNonce] += msg.value
            mstore(0x00, interactionNonce)
            mstore(0x20, ethPayments.slot)
            let slot := keccak256(0x00, 0x40)
            // no need to check for overflows as this would require sending more than the blockchain's total supply of ETH!
            sstore(slot, add(sload(slot), callvalue()))
        }
    }

    /**
     * @dev adds/removes an authorized rollup provider that can publish rollup blocks. Admin only
     * @param providerAddress address of rollup provider
     * @param valid are we adding or removing the provider?
     */
    function setRollupProvider(address providerAddress, bool valid) external override onlyOwner {
        rollupProviders[providerAddress] = valid;
        emit RollupProviderUpdated(providerAddress, valid);
    }

    /**
     * @dev sets the address of the PLONK verification smart contract. Admin only
     * @param _verifierAddress address of the verification smart contract
     */
    function setVerifier(address _verifierAddress) public override onlyOwner {
        rollupState.verifier = IVerifier(_verifierAddress);
        emit VerifierUpdated(_verifierAddress);
    }

    /**
     * @dev get the address of the PLONK verification smart contract
     * @return verifier address of the verification smart contract
     */
    function verifier() public view returns (address verifier) {
        // asm implementation to reduce compiled bytecode size
        assembly {
            verifier := and(sload(rollupState.slot), ADDRESS_MASK)
        }
    }

    /**
     * @dev Modifier to protect functions from being called while the contract is still in BETA.
     */

    modifier checkThirdPartyContractStatus() {
        if (owner() != _msgSender() && !allowThirdPartyContracts) {
            revert THIRD_PARTY_CONTRACTS_FLAG_NOT_SET();
        }
        _;
    }

    /**
     * @dev Set a flag that allows a third party dev to register Assets and bridges.
     * Protected by onlyOwner
     * @param _flag - bool if the flag should be set or not
     */

    function setAllowThirdPartyContracts(bool _flag) external override onlyOwner {
        allowThirdPartyContracts = _flag;
    }

    /**
     * @dev sets the address of the defi bridge proxy. Admin only
     * @param defiBridgeProxyAddress address of the defi bridge proxy contract
     */
    function setDefiBridgeProxy(address defiBridgeProxyAddress) public override onlyOwner {
        defiBridgeProxy = defiBridgeProxyAddress;
    }

    /**
     * @dev Approve a proofHash for spending a users deposited funds, this is one way and must be called by the owner of the funds
     * @param _proofHash - keccack256 hash of the inner proof public inputs
     */
    function approveProof(bytes32 _proofHash) public override whenNotPaused {
        // asm implementation to reduce compiled bytecode size
        assembly {
            // depositProofApprovals[msg.sender][_proofHash] = true;
            mstore(0x00, caller())
            mstore(0x20, depositProofApprovals.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, _proofHash)
            sstore(keccak256(0x00, 0x40), 1)
        }
    }

    /**
     * @dev Get the ERC20 token address of a supported asset, for a given assetId
     * @param assetId - identifier used to denote a particular asset
     */
    function getSupportedAsset(uint256 assetId) public view override returns (address) {
        // If the asset ID is >= 2^29, the asset represents a 'virtual' asset that has no ERC20 analogue
        // Virtual assets are used by defi bridges to track non-token data. E.g. to represent a loan.
        // If an assetId is *not* a virtual asset, its ERC20 address can be recovered from `supportedAssets[assetId]`
        if (assetId > 0x1fffffff) {
            revert INVALID_ASSET_ID();
        }

        // If assetId == ethAssetId (i.e. 0), this represents native ETH.
        // ERC20 token asset id values start at 1
        if (assetId == ethAssetId) {
            return address(0x0);
        }
        address result = supportedAssets[assetId - 1];
        if (result == address(0)) {
            revert INVALID_ASSET_ADDRESS();
        }
        return result;
    }

    /**
     * @dev throw if a given assetId represents a virtual asset
     * @param assetId 30-bit integer that describes the asset.
     * If assetId's 29th bit is set, it represents a virtual asset with no ERC20 equivalent
     * Virtual assets are used by defi bridges to track non-token data. E.g. to represent a loan.
     * If an assetId is *not* a virtual asset, its ERC20 address can be recovered from `supportedAssets[assetId]`
     */
    function validateAssetIdIsNotVirtual(uint256 assetId) internal pure {
        if (assetId > 0x1fffffff) {
            revert INVALID_ASSET_ID();
        }
    }

    /**
     * @dev Get the bridge contract address for a given bridgeAddressId
     * @param bridgeAddressId - identifier used to denote a particular bridge
     */
    function getSupportedBridge(uint256 bridgeAddressId) public view override returns (address) {
        return supportedBridges[bridgeAddressId - 1];
    }

    /**
     * @dev helper function to sanitise a given bridge gas limit value to be within pre-defined limits
     * @param bridgeGasLimit - the gas limit that needs to be sanitised
     */
    function sanitiseBridgeGasLimit(uint256 bridgeGasLimit) internal pure returns (uint256) {
        if (bridgeGasLimit < MIN_BRIDGE_GAS_LIMIT) {
            return MIN_BRIDGE_GAS_LIMIT;
        }
        if (bridgeGasLimit > MAX_BRIDGE_GAS_LIMIT) {
            return MAX_BRIDGE_GAS_LIMIT;
        }
        return bridgeGasLimit;
    }

    /**
     * @dev helper function to sanitise a given asset gas limit value to be within pre-defined limits
     * @param assetGasLimit - the gas limit that needs to be sanitised
     */
    function sanitiseAssetGasLimit(uint256 assetGasLimit) internal pure returns (uint256) {
        if (assetGasLimit < MIN_ERC20_GAS_LIMIT) {
            return MIN_ERC20_GAS_LIMIT;
        }
        if (assetGasLimit > MAX_ERC20_GAS_LIMIT) {
            return MAX_ERC20_GAS_LIMIT;
        }
        return assetGasLimit;
    }

    /**
     * @dev Get the gas limit for the bridge specified by bridgeAddressId
     * @param bridgeAddressId - identifier used to denote a particular bridge
     */
    function getBridgeGasLimit(uint256 bridgeAddressId) public view override returns (uint256) {
        return bridgeGasLimits[bridgeAddressId];
    }

    /**
     * @dev Get the addresses of all supported bridge contracts
     */
    function getSupportedBridges() external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory gasLimits = new uint256[](supportedBridges.length);
        for (uint256 i = 0; i < supportedBridges.length; ++i) {
            gasLimits[i] = bridgeGasLimits[i + 1];
        }
        return (supportedBridges, gasLimits);
    }

    /**
     * @dev Get the addresses of all supported ERC20 tokens
     */
    function getSupportedAssets() external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory gasLimits = new uint256[](supportedAssets.length);
        for (uint256 i = 0; i < supportedAssets.length; ++i) {
            gasLimits[i] = assetGasLimits[i + 1];
        }
        return (supportedAssets, gasLimits);
    }

    /**
     * @dev Get the status of the escape hatch, specifically retrieve whether the
     * hatch is open and also the number of blocks until the hatch will switch from
     * open to closed or vice versa
     */
    function getEscapeHatchStatus() public view override returns (bool, uint256) {
        uint256 blockNum = block.number;

        bool isOpen = blockNum % escapeBlockUpperBound >= escapeBlockLowerBound;
        uint256 blocksRemaining = 0;
        if (isOpen) {
            // num blocks escape hatch will remain open for
            blocksRemaining = escapeBlockUpperBound - (blockNum % escapeBlockUpperBound);
        } else {
            // num blocks until escape hatch will be opened
            blocksRemaining = escapeBlockLowerBound - (blockNum % escapeBlockUpperBound);
        }
        return (isOpen, blocksRemaining);
    }

    /**
     * @dev Get the balance of a user, for a particular asset, held on the user's behalf
     * by this contract
     * @param assetId - unique identifier of the asset
     * @param userAddress - Ethereum address of the user who's balance is being queried
     */
    function getUserPendingDeposit(uint256 assetId, address userAddress)
        external
        view
        override
        returns (uint256 userPendingDeposit)
    {
        assembly {
            mstore(0x00, assetId)
            mstore(0x20, userPendingDeposits.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, userAddress)
            userPendingDeposit := sload(keccak256(0x00, 0x40))
        }
    }

    /**
     * @dev Increase the userPendingDeposits mapping
     * assembly impl to reduce compiled bytecode size and improve gas costs
     */
    function increasePendingDepositBalance(
        uint256 assetId,
        address depositorAddress,
        uint256 amount
    ) internal {
        validateAssetIdIsNotVirtual(assetId);
        assembly {
            // userPendingDeposit = userPendingDeposits[assetId][depositorAddress]
            mstore(0x00, assetId)
            mstore(0x20, userPendingDeposits.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, depositorAddress)
            let userPendingDepositSlot := keccak256(0x00, 0x40)
            let userPendingDeposit := sload(userPendingDepositSlot)
            let newDeposit := add(userPendingDeposit, amount)
            if lt(newDeposit, userPendingDeposit) {
                revert(0, 0)
            }
            sstore(userPendingDepositSlot, newDeposit)
        }
    }

    /**
     * @dev Decrease the userPendingDeposits mapping
     * assembly impl to reduce compiled bytecode size. Also removes a sload op and saves a fair chunk of gas per deposit tx
     */
    function decreasePendingDepositBalance(
        uint256 assetId,
        address transferFromAddress,
        uint256 amount
    ) internal {
        validateAssetIdIsNotVirtual(assetId);
        bool insufficientDeposit = false;
        assembly {
            // userPendingDeposit = userPendingDeposits[assetId][transferFromAddress]
            mstore(0x00, assetId)
            mstore(0x20, userPendingDeposits.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, transferFromAddress)
            let userPendingDepositSlot := keccak256(0x00, 0x40)
            let userPendingDeposit := sload(userPendingDepositSlot)

            insufficientDeposit := lt(userPendingDeposit, amount)

            let newDeposit := sub(userPendingDeposit, amount)

            sstore(userPendingDepositSlot, newDeposit)
        }

        if (insufficientDeposit) {
            revert INSUFFICIENT_DEPOSIT();
        }
    }

    /**
     * @dev Set the mapping between an assetId and the address of the linked asset.
     * @param linkedToken - address of the asset
     * @param gasLimit - uint256 gas limit for ERC20 token transfers of this asset
     */
    function setSupportedAsset(address linkedToken, uint256 gasLimit) external override checkThirdPartyContractStatus {
        if (linkedToken == address(0)) {
            revert INVALID_LINKED_TOKEN_ADDRESS();
        }

        supportedAssets.push(linkedToken);

        uint256 assetId = supportedAssets.length;
        assetGasLimits[assetId] = sanitiseAssetGasLimit(gasLimit);

        emit AssetAdded(assetId, linkedToken, assetGasLimits[assetId]);
    }

    /**
     * @dev Set the mapping between an bridge contract id and the address of the linked bridge contract.
     * @param linkedBridge - address of the bridge contract
     * @param gasLimit - uint256 gas limit to send to the bridge convert function
     */

    function setSupportedBridge(address linkedBridge, uint256 gasLimit)
        external
        override
        checkThirdPartyContractStatus
    {
        if (linkedBridge == address(0)) {
            revert INVALID_LINKED_BRIDGE_ADDRESS();
        }
        supportedBridges.push(linkedBridge);

        uint256 bridgeAddressId = supportedBridges.length;
        bridgeGasLimits[bridgeAddressId] = sanitiseBridgeGasLimit(gasLimit);

        emit BridgeAdded(bridgeAddressId, linkedBridge, bridgeGasLimits[bridgeAddressId]);
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Non-permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param owner - address that can spend the deposited funds
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     */
    function depositPendingFunds(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash
    ) external payable override whenNotPaused {
        // Guard against defi bridges calling `depositPendingFunds` when processRollup calls their `convert` function
        reentrancyMutexCheck();

        if (assetId == ethAssetId) {
            if (msg.value != amount) {
                revert MSG_VALUE_WRONG_AMOUNT();
            }
            increasePendingDepositBalance(assetId, owner, amount);
        } else {
            if (msg.value != 0) {
                revert DEPOSIT_TOKENS_WRONG_PAYMENT_TYPE();
            }
            if (owner != msg.sender) {
                revert INVALID_DEPOSITOR();
            }

            address assetAddress = getSupportedAsset(assetId);
            internalDeposit(assetId, assetAddress, owner, amount);
        }

        if (proofHash != 0) {
            approveProof(proofHash);
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     * @param deadline - when the permit signature expires
     * @param v - ECDSA sig param
     * @param r - ECDSA sig param
     * @param s - ECDSA sig param
     */
    function depositPendingFundsPermit(
        uint256 assetId,
        uint256 amount,
        address depositorAddress,
        bytes32 proofHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override whenNotPaused {
        reentrancyMutexCheck();
        address assetAddress = getSupportedAsset(assetId);
        IERC20Permit(assetAddress).permit(depositorAddress, address(this), amount, deadline, v, r, s);
        internalDeposit(assetId, assetAddress, depositorAddress, amount);

        if (proofHash != '') {
            approveProof(proofHash);
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Permit flow
     * @param assetId - unique ID of the asset
     * @param amount - number of tokens being deposited
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param proofHash - the 32 byte transaction id that can spend the deposited funds
     * @param nonce - user's nonce on the erc20 contract, for replay protection
     * @param deadline - when the permit signature expires
     * @param v - ECDSA sig param
     * @param r - ECDSA sig param
     * @param s - ECDSA sig param
     */
    function depositPendingFundsPermitNonStandard(
        uint256 assetId,
        uint256 amount,
        address depositorAddress,
        bytes32 proofHash,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override whenNotPaused {
        reentrancyMutexCheck();
        address assetAddress = getSupportedAsset(assetId);
        IERC20Permit(assetAddress).permit(depositorAddress, address(this), nonce, deadline, true, v, r, s);
        internalDeposit(assetId, assetAddress, depositorAddress, amount);

        if (proofHash != '') {
            approveProof(proofHash);
        }
    }

    /**
     * @dev Deposit funds as part of the first stage of the two stage deposit. Non-permit flow
     * @param assetId - unique ID of the asset
     * @param assetAddress - address of the ERC20 asset
     * @param depositorAddress - address from which funds are being transferred to the contract
     * @param amount - amount being deposited
     */
    function internalDeposit(
        uint256 assetId,
        address assetAddress,
        address depositorAddress,
        uint256 amount
    ) internal {
        validateAssetIdIsNotVirtual(assetId);
        // check user approved contract to transfer funds, so can throw helpful error to user
        uint256 rollupAllowance = IERC20(assetAddress).allowance(depositorAddress, address(this));
        if (rollupAllowance < amount) {
            revert INSUFFICIENT_TOKEN_APPROVAL();
        }

        TokenTransfers.safeTransferFrom(assetAddress, depositorAddress, address(this), amount);
        increasePendingDepositBalance(assetId, depositorAddress, amount);

        emit Deposit(assetId, depositorAddress, amount);
    }

    /**
     * @dev Used to publish data that doesn't need to be on chain. Should eventually be published elsewhere.
     * This maybe called multiple times to work around maximum tx size limits.
     * The data will need to be reconstructed by the client.
     * @param rollupId - the rollup id this data is related to.
     * @param - the data.
     */
    function offchainData(
        uint256 rollupId,
        bytes calldata /* offchainTxData */
    ) external override whenNotPaused {
        emit OffchainData(rollupId, msg.sender);
    }

    /**
     * @dev Process a rollup - decode the rollup, update relevant state variables and
     * verify the proof
     * @param - cryptographic proof data associated with a rollup
     * @param signatures - bytes array of secp256k1 ECDSA signatures, authorising a transfer of tokens
     * from the publicOwner for the particular inner proof in question. There is a signature for each
     * inner proof.
     *
     * Structure of each signature in the bytes array is:
     * 0x00 - 0x20 : r
     * 0x20 - 0x40 : s
     * 0x40 - 0x60 : v (in form: 0x0000....0001b for example)
     *
     * @param - offchainTxData Note: not used in the logic
     * of the rollupProcessor contract, but called here as a convenient to place data on chain
     */
    function processRollup(
        bytes calldata, /* encodedProofData */
        bytes calldata signatures
    ) external override whenNotPaused {
        reentrancyMutexCheck();
        setReentrancyMutex();
        // 1. Process a rollup if the escape hatch is open or,
        // 2. There msg.sender is an authorised rollup provider
        // 3. Always transfer fees to the passed in feeReceiver
        (bool isOpen, ) = getEscapeHatchStatus();
        if (!(rollupProviders[msg.sender] || isOpen)) {
            revert INVALID_PROVIDER();
        }

        (bytes memory proofData, uint256 numTxs, uint256 publicInputsHash) = decodeProof();
        address rollupBeneficiary = extractRollupBeneficiaryAddress(proofData);

        processRollupProof(proofData, signatures, numTxs, publicInputsHash, rollupBeneficiary);

        transferFee(proofData, rollupBeneficiary);

        clearReentrancyMutex();
    }

    /**
     * @dev processes a rollup proof. Will verify the proof's correctness and use the provided
     * proof data to update the rollup state + merkle roots, as well as validate/enact any deposits/withdrawals in the block.
     * Finally any defi interactions specified in the block will be executed
     * @param proofData the block's proof data (contains PLONK proof and public input data linked to the proof)
     * @param signatures ECDSA signatures from users authorizing deposit transactions
     * @param numTxs the number of transactions in the block
     * @param publicInputsHash the SHA256 hash of the proof's public inputs
     */
    function processRollupProof(
        bytes memory proofData,
        bytes memory signatures,
        uint256 numTxs,
        uint256 publicInputsHash,
        address rollupBeneficiary
    ) internal {
        uint256 rollupId = verifyProofAndUpdateState(proofData, publicInputsHash);
        processDepositsAndWithdrawals(proofData, numTxs, signatures);
        bytes32[] memory nextDefiHashes = processDefiBridges(proofData, rollupBeneficiary);
        emit RollupProcessed(rollupId, nextDefiHashes, msg.sender);
    }

    /**
     * @dev Verify the zk proof and update the contract state variables with those provided by the rollup.
     * @param proofData - cryptographic zk proof data. Passed to the verifier for verification.
     */
    function verifyProofAndUpdateState(bytes memory proofData, uint256 publicInputsHash)
        internal
        returns (uint256 rollupId)
    {
        // Verify the rollup proof.
        //
        // We manually call the verifier contract via assembly to save on gas costs and to reduce contract bytecode size
        assembly {
            /**
             * Validate correctness of zk proof.
             *
             * 1st Item is to format verifier calldata.
             **/

            // Our first input param `encodedProofData` contains the concatenation of
            // encoded 'broadcasted inputs' and the actual zk proof data.
            // (The `boadcasted inputs` is converted into a 32-byte SHA256 hash, which is
            // validated to equal the first public inputs of the zk proof. This is done in `Decoder.sol`).
            // We need to identify the location in calldata that points to the start of the zk proof data.

            // Step 1: compute size of zk proof data and its calldata pointer.
            /**
                Data layout for `bytes encodedProofData`...

                0x00 : 0x20 : length of array
                0x20 : 0x20 + header : root rollup header data
                0x20 + header : 0x24 + header : X, the length of encoded inner join-split public inputs
                0x24 + header : 0x24 + header + X : (inner join-split public inputs)
                0x24 + header + X : 0x28 + header + X : Y, the length of the zk proof data
                0x28 + header + X : 0x28 + haeder + X + Y : zk proof data

                We need to recover the numeric value of `0x28 + header + X` and `Y`
             **/
            // Begin by getting length of encoded inner join-split public inputs.
            // `calldataload(0x04)` points to start of bytes array. Add 0x24 to skip over length param and function signature.
            // The calldata param 4 bytes *after* the header is the length of the pub inputs array. However it is a packed 4-byte param.
            // To extract it, we subtract 24 bytes from the calldata pointer and mask off all but the 4 least significant bytes.
            let encodedInnerDataSize := and(
                calldataload(add(add(calldataload(0x04), 0x24), sub(ROLLUP_HEADER_LENGTH, 0x18))),
                0xffffffff
            )

            // add 8 bytes to skip over the two packed params that follow the rollup header data
            // broadcastedDataSize = inner join-split pubinput size + header size
            let broadcastedDataSize := add(add(ROLLUP_HEADER_LENGTH, 8), encodedInnerDataSize)

            // Compute zk proof data size by subtracting broadcastedDataSize from overall length of bytes encodedProofsData
            let zkProofDataSize := sub(calldataload(add(calldataload(0x04), 0x04)), broadcastedDataSize)

            // Compute calldata pointer to start of zk proof data by adding calldata offset to broadcastedDataSize
            // (+0x24 skips over function signature and length param of bytes encodedProofData)
            let zkProofDataPtr := add(broadcastedDataSize, add(calldataload(0x04), 0x24))

            // Step 2: Format calldata for verifier contract call.

            // Get free memory pointer - we copy calldata into memory starting here
            let dataPtr := mload(0x40)

            // We call the function `verify(bytes,uint256)`
            // The function signature is 0xac318c5d
            // Calldata map is:
            // 0x00 - 0x04 : 0xac318c5d
            // 0x04 - 0x24 : 0x40 (number of bytes between 0x04 and the start of the `proofData` array at 0x44)
            // 0x24 - 0x44 : publicInputsHash
            // 0x44 - .... : proofData
            mstore8(dataPtr, 0xac)
            mstore8(add(dataPtr, 0x01), 0x31)
            mstore8(add(dataPtr, 0x02), 0x8c)
            mstore8(add(dataPtr, 0x03), 0x5d)
            mstore(add(dataPtr, 0x04), 0x40)
            mstore(add(dataPtr, 0x24), publicInputsHash)
            mstore(add(dataPtr, 0x44), zkProofDataSize) // length of zkProofData bytes array
            calldatacopy(add(dataPtr, 0x64), zkProofDataPtr, zkProofDataSize) // copy the zk proof data into memory

            // Step 3: Call our verifier contract. If does not return any values, but will throw an error if the proof is not valid
            // i.e. verified == false if proof is not valid
            let verifierAddress := and(sload(rollupState.slot), ADDRESS_MASK)
            let proof_verified := staticcall(gas(), verifierAddress, dataPtr, add(zkProofDataSize, 0x64), 0x00, 0x00)

            // Check the proof is valid!
            if iszero(proof_verified) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Validate and update state hash
        rollupId = validateAndUpdateMerkleRoots(proofData);
    }

    /**
     * @dev Extract public inputs and validate they are inline with current contract rollupState.
     * @param proofData - Rollup proof data.
     */
    function validateAndUpdateMerkleRoots(bytes memory proofData) internal returns (uint256) {
        (
            uint256 rollupId,
            bytes32 oldStateHash,
            bytes32 newStateHash,
            uint32 numDataLeaves,
            uint32 dataStartIndex
        ) = computeRootHashes(proofData);

        bytes32 expectedStateHash = rollupStateHash;
        if (oldStateHash != expectedStateHash) {
            revert INCORRECT_STATE_HASH(oldStateHash, newStateHash);
        }

        unchecked {
            uint32 storedDataSize = rollupState.datasize;
            // Ensure we are inserting at the next subtree boundary.
            if (storedDataSize % numDataLeaves == 0) {
                if (dataStartIndex != storedDataSize) {
                    revert INCORRECT_DATA_START_INDEX(dataStartIndex, storedDataSize);
                }
            } else {
                uint256 expected = storedDataSize + numDataLeaves - (storedDataSize % numDataLeaves);
                if (dataStartIndex != expected) {
                    revert INCORRECT_DATA_START_INDEX(dataStartIndex, expected);
                }
            }

            rollupStateHash = newStateHash;
            rollupState.datasize = dataStartIndex + numDataLeaves;
        }
        return rollupId;
    }

    /**
     * @dev Process deposits and withdrawls.
     * @param proofData - the proof data
     * @param numTxs - number of transactions rolled up in the proof
     * @param signatures - bytes array of secp256k1 ECDSA signatures, authorising a transfer of tokens
     */
    function processDepositsAndWithdrawals(
        bytes memory proofData,
        uint256 numTxs,
        bytes memory signatures
    ) internal {
        uint256 sigIndex = 0x00;
        uint256 proofDataPtr;
        uint256 end;
        assembly {
            // add 0x20 to skip over 1st member of the bytes type (the length field).
            // Also skip over the rollup header.
            proofDataPtr := add(ROLLUP_HEADER_LENGTH, add(proofData, 0x20))

            // compute the position of proofDataPtr after we iterate through every transaction
            end := add(proofDataPtr, mul(numTxs, TX_PUBLIC_INPUT_LENGTH))
        }
        uint256 stepSize = TX_PUBLIC_INPUT_LENGTH;

        // This is a bit of a hot loop, we iterate over every tx to determine whether to process deposits or withdrawals.
        while (proofDataPtr < end) {
            // extract the minimum information we need to determine whether to skip this iteration
            uint256 publicValue;
            assembly {
                publicValue := mload(add(proofDataPtr, 0xa0))
            }
            if (publicValue > 0) {
                uint256 proofId;
                uint256 assetId;
                address publicOwner;
                assembly {
                    proofId := mload(proofDataPtr)
                    assetId := mload(add(proofDataPtr, 0xe0))
                    publicOwner := mload(add(proofDataPtr, 0xc0))
                }

                if (proofId == 1) {
                    // validate user has approved deposit
                    bytes32 digest;
                    assembly {
                        // compute the tx id to check if user has approved tx
                        digest := keccak256(proofDataPtr, stepSize)
                    }
                    // check if there is an existing entry in depositProofApprovals
                    // if there is, no further work required.
                    // we don't need to clear `depositProofApprovals[publicOwner][digest]` because proofs cannot be re-used.
                    // A single proof describes the creation of 2 output notes and the addition of 2 input note nullifiers
                    // (both of these nullifiers can be categorised as "fake". They may not map to existing notes but are still inserted in the nullifier set)
                    // Replaying the proof will fail to satisfy the rollup circuit's non-membership check on the input nullifiers.
                    // We avoid resetting `depositProofApprovals` because that would cost additional gas post-London hard fork.
                    if (!depositProofApprovals[publicOwner][digest]) {
                        // extract and validate signature
                        // we can create a bytes memory container for the signature without allocating new memory,
                        // by overwriting the previous 32 bytes in the `signatures` array with the 'length' of our synthetic byte array (92)
                        // we store the memory we overwrite in `temp`, so that we can restore it
                        bytes memory signature;
                        uint256 temp;
                        assembly {
                            // set `signature` to point to 32 bytes less than the desired `r, s, v` values in `signatures`
                            signature := add(signatures, sigIndex)
                            // cache the memory we're about to overwrite
                            temp := mload(signature)
                            // write in a 92-byte 'length' parameter into the `signature` bytes array
                            mstore(signature, 0x60)
                        }

                        bytes32 hashedMessage = RollupProcessorLibrary.getSignedMessageForTxId(digest);

                        RollupProcessorLibrary.validateSheildSignatureUnpacked(hashedMessage, signature, publicOwner);
                        // restore the memory we overwrote
                        assembly {
                            mstore(signature, temp)
                            sigIndex := add(sigIndex, 0x60)
                        }
                    }
                    decreasePendingDepositBalance(assetId, publicOwner, publicValue);
                }

                if (proofId == 2) {
                    withdraw(publicValue, publicOwner, assetId);
                }
            }
            // don't check for overflow, would take > 2^200 iterations of this loop for that to happen!
            unchecked {
                proofDataPtr += TX_PUBLIC_INPUT_LENGTH;
            }
        }
    }

    /**
     * @dev Unpack the bridgeId into a BridgeData struct
     * @param bridgeId - Bit-array that encodes data that describes a DeFi bridge.
     *
     * Structure of the bit array is as follows (starting at least significant bit):
     * | bit range | parameter | description
     * | 0 - 32    | bridgeAddressId | The address ID. Bridge address = `supportedBridges[bridgeAddressId]`
     * | 32 - 62   | inputAssetIdA    | Input asset ID. Asset address = `supportedAssets[inputAssetIdA]`
     * | 62 - 92   | outputAssetIdA  | First output asset ID |
     * | 92 - 122  | outputAssetIdB  | Second output asset ID (if bridge has 2nd output asset) |
     * | 122 - 154 | inputAssetIdB | Second input asset ID. If virtual, is defi interaction nonce of interaction that produced the note |
     * | 154 - 186 | bitConfig | Bit-array that contains boolean bridge settings |
     * | 186 - 250 | auxData | 64 bits of custom data to be passed to the bridge contract. Structure is defined/checked by the bridge contract |
     *
     * Structure of the `bigConfig` parameter is as follows
     * | bit | parameter | description |
     * | 0   | firstInputAssetVirtual  | is the first input asset virtual? Currently always false, support planned for future update |
     * | 1   | secondInputAssetVirtual | is the second input asset virtual? Virtual assets have no ERC20 token analogue |
     * | 2   | firstOutputAssetVirtual | is the first output asset virtual? Currently always false, support planned for future update |
     * | 3   | secondOutputAssetVirtual| is the second output asset virtual?
     * | 4   | secondInputReal         | does the second input note represent a non-virtual, real ERC20 token? Currently always false, support planned for future update |
     * | 5   | secondOutputReal        | does the second output note represent a non-virtual, real ERC20 token? |
     *
     * Brief note on virtual assets: Virtual assets are assets that don't have an ERC20 token analogue and exist solely as notes within the Aztec network.
     * They can be created/spent as a result of DeFi interactions. They are used to enable defi bridges to track internally-defined data without having to
     * mint a new token on-chain.
     * An example use of a virtual asset would a virtual loan asset that tracks an outstanding debt that must be repaid to recover collateral deposited into the bridge.
     *
     * @return bridgeData - struct that contains bridgeId data in a human-readable form.
     */
    function getBridgeData(uint256 bridgeId) internal view returns (BridgeData memory bridgeData) {
        assembly {
            mstore(bridgeData, and(bridgeId, MASK_THIRTY_TWO_BITS)) // bridgeAddressId
            mstore(add(bridgeData, 0x40), and(shr(INPUT_ASSET_ID_A_SHIFT, bridgeId), MASK_THIRTY_BITS)) // inputAssetIdA
            mstore(add(bridgeData, 0x60), and(shr(OUTPUT_ASSET_ID_A_SHIFT, bridgeId), MASK_THIRTY_BITS)) // outputAssetIdA
            mstore(add(bridgeData, 0x80), and(shr(OUTPUT_ASSET_ID_B_SHIFT, bridgeId), MASK_THIRTY_BITS)) // outputAssetIdB
            mstore(add(bridgeData, 0xa0), and(shr(INPUT_ASSET_ID_B_SHIFT, bridgeId), MASK_THIRTY_BITS)) // inputAssetIdB
            mstore(add(bridgeData, 0xc0), and(shr(AUX_DATA_SHIFT, bridgeId), MASK_SIXTY_FOUR_BITS)) // auxData

            let bitConfig := and(shr(BITCONFIG_SHIFT, bridgeId), MASK_THIRTY_TWO_BITS)
            // bitConfig = bit mask that contains bridge ID settings
            // bit 0 = first input asset virtual?
            // bit 1 = second input asset virtual?
            // bit 2 = first output asset virtual?
            // bit 3 = second output asset virtual?
            // bit 4 = second input asset real?
            // bit 5 = second output asset real?
            mstore(add(bridgeData, 0xe0), and(bitConfig, 1)) // firstInputVirtual ((bitConfit) & 1) == 1
            mstore(add(bridgeData, 0x100), eq(and(shr(1, bitConfig), 1), 1)) // secondInputVirtual ((bitConfig >> 1) & 1) == 1
            mstore(add(bridgeData, 0x120), eq(and(shr(2, bitConfig), 1), 1)) // firstOutputVirtual ((bitConfig >> 2) & 1) == 1
            mstore(add(bridgeData, 0x140), eq(and(shr(3, bitConfig), 1), 1)) // secondOutputVirtual ((bitConfig >> 3) & 1) == 1
            mstore(add(bridgeData, 0x160), eq(and(shr(4, bitConfig), 1), 1)) // secondInputReal ((bitConfig >> 4) & 1) == 1
            mstore(add(bridgeData, 0x180), eq(and(shr(5, bitConfig), 1), 1)) // secondOutputReal ((bitConfig >> 5) & 1) == 1
        }

        // potential conflicting states that are explicitly ruled out by circuit constraints:
        if (bridgeData.secondInputReal && bridgeData.secondInputVirtual) {
            revert BRIDGE_ID_IS_INCONSISTENT();
        }
        if (bridgeData.secondOutputReal && bridgeData.secondOutputVirtual) {
            revert BRIDGE_ID_IS_INCONSISTENT();
        }
        bridgeData.bridgeAddress = supportedBridges[bridgeData.bridgeAddressId - 1];
        bool bothOutputsReal = (!bridgeData.firstOutputVirtual && bridgeData.secondOutputReal);
        bool bothOutputsVirtual = (bridgeData.firstOutputVirtual && bridgeData.secondOutputVirtual);
        if ((bothOutputsReal || bothOutputsVirtual) && (bridgeData.outputAssetIdA == bridgeData.outputAssetIdB)) {
            revert BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(bridgeData.outputAssetIdA);
        }
        bool bothInputsReal = (!bridgeData.firstInputVirtual && bridgeData.secondInputReal);
        bool bothInputsVirtual = (bridgeData.firstInputVirtual && bridgeData.secondInputVirtual);
        if ((bothInputsReal || bothInputsVirtual) && (bridgeData.outputAssetIdA == bridgeData.outputAssetIdB)) {
            revert BRIDGE_WITH_IDENTICAL_OUTPUT_ASSETS(bridgeData.outputAssetIdA);
        }
        bridgeData.bridgeGasLimit = getBridgeGasLimit(bridgeData.bridgeAddressId);
    }

    /**
     * @dev Get the four input/output assets associated with a DeFi bridge
     * @param bridgeData - Information about the DeFi bridge
     * @param defiInteractionNonce - The defi interaction nonce
     *
     * @return inputAssetA inputAssetB outputAssetA outputAssetB : input and output assets represented as AztecAsset structs
     */
    function getAztecAssetTypes(BridgeData memory bridgeData, uint256 defiInteractionNonce)
        internal
        view
        returns (
            AztecTypes.AztecAsset memory inputAssetA,
            AztecTypes.AztecAsset memory inputAssetB,
            AztecTypes.AztecAsset memory outputAssetA,
            AztecTypes.AztecAsset memory outputAssetB
        )
    {
        if (bridgeData.firstInputVirtual) {
            // asset id will be defi interaction nonce that created note
            inputAssetA.id = bridgeData.inputAssetIdA;
            inputAssetA.erc20Address = address(0x0);
            inputAssetA.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else {
            inputAssetA.id = bridgeData.inputAssetIdA;
            inputAssetA.erc20Address = getSupportedAsset(bridgeData.inputAssetIdA);
            inputAssetA.assetType = inputAssetA.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        }
        if (bridgeData.firstOutputVirtual) {
            // use nonce as asset id.
            outputAssetA.id = defiInteractionNonce;
            outputAssetA.erc20Address = address(0x0);
            outputAssetA.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else {
            outputAssetA.id = bridgeData.outputAssetIdA;
            outputAssetA.erc20Address = getSupportedAsset(bridgeData.outputAssetIdA);
            outputAssetA.assetType = outputAssetA.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        }

        if (bridgeData.secondInputVirtual) {
            // asset id will be defi interaction nonce that created note
            inputAssetB.id = bridgeData.inputAssetIdB;
            inputAssetB.erc20Address = address(0x0);
            inputAssetB.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else if (bridgeData.secondInputReal) {
            inputAssetB.id = bridgeData.inputAssetIdB;
            inputAssetB.erc20Address = getSupportedAsset(bridgeData.inputAssetIdB);
            inputAssetB.assetType = inputAssetB.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        } else {
            inputAssetB.id = 0;
            inputAssetB.erc20Address = address(0x0);
            inputAssetB.assetType = AztecTypes.AztecAssetType.NOT_USED;
        }

        if (bridgeData.secondOutputVirtual) {
            // use nonce as asset id.
            outputAssetB.id = defiInteractionNonce;
            outputAssetB.erc20Address = address(0x0);
            outputAssetB.assetType = AztecTypes.AztecAssetType.VIRTUAL;
        } else if (bridgeData.secondOutputReal) {
            outputAssetB.id = bridgeData.outputAssetIdB;
            outputAssetB.erc20Address = getSupportedAsset(bridgeData.outputAssetIdB);
            outputAssetB.assetType = outputAssetB.erc20Address == address(0x0)
                ? AztecTypes.AztecAssetType.ETH
                : AztecTypes.AztecAssetType.ERC20;
        } else {
            outputAssetB.id = 0;
            outputAssetB.erc20Address = address(0x0);
            outputAssetB.assetType = AztecTypes.AztecAssetType.NOT_USED;
        }
    }

    /**
     * @dev Get the length of the defi interaction hashes array and the number of pending interactions
     *
     * @return defiInteractionHashesLength the complete length of the defi interaction array
     * @return numPendingInteractions the current number of pending defi interactions
     */
    function getDefiHashesLengths()
        internal
        view
        returns (uint256 defiInteractionHashesLength, uint256 numPendingInteractions)
    {
        assembly {
            // retrieve the total length of the defi interactions array and also the number of pending interactions to a maximum of NUMBER_OF_BRIDGE_CALLS
            let state := sload(rollupState.slot)
            {
                defiInteractionHashesLength := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))
                numPendingInteractions := defiInteractionHashesLength
                if gt(numPendingInteractions, NUMBER_OF_BRIDGE_CALLS) {
                    numPendingInteractions := NUMBER_OF_BRIDGE_CALLS
                }
            }
        }
    }

    /**
     * @dev Get the set of hashes that comprise the current pending defi interactions
     *
     * @return hashes the set of valid (i.e. non-zero) hashes that comprise the pending defi interactions
     * @return nextExpectedHash the hash of all hashes (including zero hashes) that comprise the pending defi interactions
     */
    function calculateNextExpectedDefiHash() internal view returns (bytes32[] memory hashes, bytes32 nextExpectedHash) {
        /**----------------------------------------
         * Compute nextExpectedHash
         *-----------------------------------------
         *
         * The storage slot `defiInteractionHashes` points to an array that represents the
         * set of defi interactions from previous blocks that have been resolved.
         *
         * We need to take the interaction result data from each of the above defi interactions,
         * and add that data into the Aztec L2 merkle tree that contains defi interaction results
         * (the "Defi Tree". Its merkle root is one of the inputs to the storage variable `rollupStateHash`)
         *
         * It is the rollup provider's responsibility to perform these additions.
         * In the current block being processed, the rollup provider must take these pending interaction results,
         * create commitments to each result and insert each commitment into the next empty leaf of the defi tree.
         *
         * The following code validates that this has happened! This is how:
         *
         * Part 1: What are we checking?
         *
         * The rollup circuit will receive, as a private input from the rollup provider, the pending defi interaction results
         * (`bridgeId`, `totalInputValue`, `totalOutputValueA`, `totalOutputValueB`, `result`)
         * The rollup circuit will compute the SHA256 hash of each interaction result (the defiInteractionHash)
         * Finally the SHA256 hash of `NUMBER_OF_BRIDGE_CALLS` of these defiInteractionHash values is computed.
         * (if there are fewer than `NUMBER_OF_BRIDGE_CALLS` pending defi interaction results, the SHA256 hash of an empty defi interaction result is used instead. i.e. all variable values are set to 0)
         * The above SHA256 hash, the `pendingDefiInteractionHash` is one of the broadcasted values that forms the `publicInputsHash` public input to the rollup circuit.
         * When verifying a rollup proof, this smart contract will compute `publicInputsHash` from the input calldata. The PLONK Verifier smart contract will then validate
         * that our computed value for `publicInputHash` matches the value used when generating the rollup proof.
         *
         * TLDR of the above: our proof data contains a variable `pendingDefiInteractionHash`, which is the CLAIMED VALUE of SHA256 hashing the SHA256 hashes of the defi interactions that have resolved but whose data has not yet been added into the defi tree.
         *
         * Part 2: How do we check `pendingDefiInteractionHash` is correct???
         *
         * This contract will call `DefiBridgeProxy.convert` (via delegatecall) on every new defi interaction present in the block.
         * The return values from the bridge proxy contract are used to construct a defi interaction result. Its hash is then computed
         * and stored in `defiInteractionHashes[]`.
         *
         * N.B. It's very important that DefiBridgeProxy does not call selfdestruct, or makes a delegatecall out to a contract that can selfdestruct :o
         *
         * Similarly, when async defi interactions resolve, the interaction result is stored in `asyncDefiInteractionHashes[]`. At the end of the processDefiBridges function,
         * the contents of the async array is copied into `defiInteractionHashes` (i.e. async interaction results are delayed by 1 rollup block. This is to prevent griefing attacks where
         * the rollup state changes between the time taken for a rollup tx to be constructed and the rollup tx to be mined)
         *
         * We use the contents of `defiInteractionHashes` to reconstruct `pendingDefiInteractionHash`, and validate it matches the value present in calldata and
         * therefore the value used in the rollup circuit when this block's rollup proof was constructed.
         * This validates that all of the required defi interaction results were added into the defi tree by the rollup provider
         * (the circuit logic enforces this, we just need to check the rollup provider used the correct inputs)
         */
        (uint256 defiInteractionHashesLength, uint256 numPendingInteractions) = getDefiHashesLengths();
        uint256 offset = defiInteractionHashesLength - numPendingInteractions;
        assembly {
            // allocate the output array of hashes
            hashes := mload(0x40)
            let hashData := add(hashes, 0x20)
            // update the free memory pointer to point past the end of our array
            // our array will consume 32 bytes for the length field plus NUMBER_OF_BRIDGE_BYTES for all of the hashes
            mstore(0x40, add(hashes, add(NUMBER_OF_BRIDGE_BYTES, 0x20)))
            // set the length of hashes to only include the non-zero hash values
            // although this function will write all of the hashes into our allocated memory, we only want to return the non-zero hashes
            mstore(hashes, numPendingInteractions)

            // Start by getting the defi interaction hashes array slot value
            mstore(0x00, defiInteractionHashes.slot)
            let sloadOffset := keccak256(0x00, 0x20)
            let i := 0

            // Iterate over numPendingInteractions (will be between 0 and NUMBER_OF_BRIDGE_CALLS)
            // Load defiInteractionHashes[offset + i] and store in memory
            // in order to compute SHA2 hash (nextExpectedHash)
            for {

            } lt(i, numPendingInteractions) {
                i := add(i, 0x01)
            } {
                mstore(add(hashData, mul(i, 0x20)), sload(add(sloadOffset, add(offset, i))))
            }

            // If numPendingInteractions < NUMBER_OF_BRIDGE_CALLS, continue iterating up to NUMBER_OF_BRIDGE_CALLS, this time
            // inserting the "zero hash", the result of sha256(emptyDefiInteractionResult)
            for {

            } lt(i, NUMBER_OF_BRIDGE_CALLS) {
                i := add(i, 0x01)
            } {
                mstore(add(hashData, mul(i, 0x20)), DEFI_RESULT_ZERO_HASH)
            }
            pop(staticcall(gas(), 0x2, hashData, NUMBER_OF_BRIDGE_BYTES, 0x00, 0x20))
            nextExpectedHash := mod(mload(0x00), CIRCUIT_MODULUS)
        }
    }

    /**
     * @dev Process defi interactions.
     *      1. pop NUMBER_OF_BRIDGE_CALLS (if available) interaction hashes off of `defiInteractionHashes`,
     *         validate their hash (calculated at the end of the previous rollup and stored as nextExpectedDefiInteractionsHash) equals `numPendingInteractions`
     *         (this validates that rollup block has added these interaction results into the L2 data tree)
     *      2. iterate over rollup block's new defi interactions (up to NUMBER_OF_BRIDGE_CALLS). Trigger interactions by
     *         calling DefiBridgeProxy contract. Record results in either `defiInteractionHashes` (for synchrohnous txns)
     *         or, for async txns, the `pendingDefiInteractions` mapping
     *      3. copy the contents of `asyncInteractionHashes` into `defiInteractionHashes` && clear `asyncInteractionHashes`
     *      4. calculate the next value of nextExpectedDefiInteractionsHash from the new set of defiInteractionHashes
     * @param proofData - the proof data
     * @param rollupBeneficiary - the address that should be paid any subsidy for processing a defi bridge
     * @return nextExpectedHashes - the set of non-zero hashes that comprise the current pending defi interactions
     */
    function processDefiBridges(bytes memory proofData, address rollupBeneficiary)
        internal
        returns (bytes32[] memory nextExpectedHashes)
    {
        // Verify that nextExpectedDefiInteractionsHash equals the value given in the rollup
        // Then remove the set of pending hashes
        {
            // Extract the claimed value of previousDefiInteractionHash present in the proof data
            bytes32 providedDefiInteractionsHash = extractPrevDefiInteractionHash(proofData);

            // Validate the stored interactionHash matches the value used when making the rollup proof!
            if (providedDefiInteractionsHash != prevDefiInteractionsHash) {
                revert INCORRECT_PREVIOUS_DEFI_INTERACTION_HASH(providedDefiInteractionsHash, prevDefiInteractionsHash);
            }
            (uint256 defiInteractionHashesLength, uint256 numPendingInteractions) = getDefiHashesLengths();
            // numPendingInteraction equals the number of interactions expected to be in the given rollup
            // this is the length of the defiInteractionHashes array, capped at the NUM_BRIDGE_CALLS as per the following
            // numPendingInteractions = min(defiInteractionsHashesLength, numberOfBridgeCalls)
            // Compute the offset we use to index `defiInteractionHashes[]`
            // If defiInteractionHashes.length > numberOfBridgeCalls, offset = defiInteractionhashes.length - numberOfBridgeCalls.
            // Else offset = 0
            uint256 offset = defiInteractionHashesLength - numPendingInteractions;

            assembly {
                // Update DefiInteractionHashes.length (we've reduced length by up to numberOfBridgeCalls)
                // this effectively truncates the array at offset
                let state := sload(rollupState.slot)
                let oldState := and(not(shl(DEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)
                let newState := or(oldState, shl(DEFIINTERACTIONHASHES_BIT_OFFSET, offset))
                sstore(rollupState.slot, newState)
            }
        }
        uint256 interactionNonce = getRollupId(proofData) * NUMBER_OF_BRIDGE_CALLS;

        // ### Process DefiBridge Calls
        uint256 proofDataPtr;
        uint256 defiInteractionHashesLength;
        assembly {
            proofDataPtr := add(proofData, BRIDGE_IDS_OFFSET)
            defiInteractionHashesLength := and(
                ARRAY_LENGTH_MASK,
                shr(DEFIINTERACTIONHASHES_BIT_OFFSET, sload(rollupState.slot))
            )
        }
        BridgeResult memory bridgeResult;
        assembly {
            bridgeResult := mload(0x40)
            mstore(0x40, add(bridgeResult, 0x80))
        }
        for (uint256 i = 0; i < NUMBER_OF_BRIDGE_CALLS; ++i) {
            uint256 bridgeId;
            assembly {
                bridgeId := mload(proofDataPtr)
            }
            if (bridgeId == 0) {
                // no more bridges to call
                break;
            }
            uint256 totalInputValue;
            assembly {
                totalInputValue := mload(add(proofDataPtr, mul(0x20, NUMBER_OF_BRIDGE_CALLS)))
            }
            if (totalInputValue == 0) {
                revert ZERO_TOTAL_INPUT_VALUE();
            }

            BridgeData memory bridgeData = getBridgeData(bridgeId);

            (
                AztecTypes.AztecAsset memory inputAssetA,
                AztecTypes.AztecAsset memory inputAssetB,
                AztecTypes.AztecAsset memory outputAssetA,
                AztecTypes.AztecAsset memory outputAssetB
            ) = getAztecAssetTypes(bridgeData, interactionNonce);

            assembly {
                // call the following function of DefiBridgeProxy via delegatecall...
                //     function convert(
                //          address bridgeAddress,
                //          AztecTypes.AztecAsset calldata inputAssetA,
                //          AztecTypes.AztecAsset calldata inputAssetB,
                //          AztecTypes.AztecAsset calldata outputAssetA,
                //          AztecTypes.AztecAsset calldata outputAssetB,
                //          uint256 totalInputValue,
                //          uint256 interactionNonce,
                //          uint256 auxInputData,
                //          uint256 ethPaymentsSlot,
                //          address rollupBeneficary
                //     )

                // Construct the calldata we send to DefiBridgeProxy
                // mPtr = memory pointer. Set to free memory location (0x40)
                let mPtr := mload(0x40)
                // first 4 bytes is the function signature
                mstore(mPtr, DEFI_BRIDGE_PROXY_CONVERT_SELECTOR)
                mPtr := add(mPtr, 0x04)
                {
                    let bridgeAddress := mload(add(bridgeData, 0x20))
                    mstore(mPtr, bridgeAddress)
                }

                mstore(add(mPtr, 0x20), mload(inputAssetA))
                mstore(add(mPtr, 0x40), mload(add(inputAssetA, 0x20)))
                mstore(add(mPtr, 0x60), mload(add(inputAssetA, 0x40)))
                mstore(add(mPtr, 0x80), mload(inputAssetB))
                mstore(add(mPtr, 0xa0), mload(add(inputAssetB, 0x20)))
                mstore(add(mPtr, 0xc0), mload(add(inputAssetB, 0x40)))
                mstore(add(mPtr, 0xe0), mload(outputAssetA))
                mstore(add(mPtr, 0x100), mload(add(outputAssetA, 0x20)))
                mstore(add(mPtr, 0x120), mload(add(outputAssetA, 0x40)))
                mstore(add(mPtr, 0x140), mload(outputAssetB))
                mstore(add(mPtr, 0x160), mload(add(outputAssetB, 0x20)))
                mstore(add(mPtr, 0x180), mload(add(outputAssetB, 0x40)))
                mstore(add(mPtr, 0x1a0), totalInputValue)
                mstore(add(mPtr, 0x1c0), interactionNonce)

                {
                    let auxData := mload(add(bridgeData, 0xc0))
                    mstore(add(mPtr, 0x1e0), auxData)
                }
                mstore(add(mPtr, 0x200), ethPayments.slot)
                mstore(add(mPtr, 0x220), rollupBeneficiary)

                // Call the bridge proxy via delegatecall!
                // We want the proxy to share state with the rollup processor, as the proxy is the entity sending/recovering tokens from the bridge contracts.
                // We wrap this logic in a delegatecall so that if the call fails (i.e. the bridge interaction fails), we can unwind bridge-interaction specific state changes,
                // without reverting the entire transaction.
                let success := delegatecall(
                    mload(add(bridgeData, 0x1a0)), // bridgeData.gasSentToBridge
                    sload(defiBridgeProxy.slot),
                    sub(mPtr, 0x04),
                    0x244,
                    mPtr,
                    0x60
                )

                switch success
                case 1 {
                    mstore(bridgeResult, mload(mPtr)) // outputValueA
                    mstore(add(bridgeResult, 0x20), mload(add(mPtr, 0x20))) // outputValueB
                    mstore(add(bridgeResult, 0x40), mload(add(mPtr, 0x40))) // isAsync
                    mstore(add(bridgeResult, 0x60), 1) // success
                }
                default {
                    // If the call failed, mark this interaction as failed. No tokens have been exchanged, users can
                    // use the "claim" circuit to recover the initial tokens they sent to the bridge
                    mstore(bridgeResult, 0) // outputValueA
                    mstore(add(bridgeResult, 0x20), 0) // outputValueB
                    mstore(add(bridgeResult, 0x40), 0) // isAsync
                    mstore(add(bridgeResult, 0x60), 0) // success
                }
            }

            if (!(bridgeData.secondOutputReal || bridgeData.secondOutputVirtual)) {
                bridgeResult.outputValueB = 0;
            }

            // emit events and update state
            assembly {
                // if interaction is Async, update pendingDefiInteractions
                // if interaction is synchronous, compute the interaction hash and add to defiInteractionHashes
                switch mload(add(bridgeResult, 0x40)) // switch isAsync
                case 1 {
                    let mPtr := mload(0x40)
                    // emit AsyncDefiBridgeProcessed(indexed bridgeId, indexed interactionNonce, totalInputValue)
                    {
                        mstore(mPtr, totalInputValue)
                        log3(mPtr, 0x20, ASYNC_BRIDGE_PROCESSED_SIGHASH, bridgeId, interactionNonce)
                    }
                    // pendingDefiInteractions[interactionNonce] = PendingDefiBridgeInteraction(bridgeId, totalInputValue, 0)
                    mstore(0x00, interactionNonce)
                    mstore(0x20, pendingDefiInteractions.slot)
                    let pendingDefiInteractionsSlotBase := keccak256(0x00, 0x40)

                    sstore(pendingDefiInteractionsSlotBase, bridgeId)
                    sstore(add(pendingDefiInteractionsSlotBase, 0x01), totalInputValue)
                }
                default {
                    let mPtr := mload(0x40)
                    // prepare the data required to publish the DefiBridgeProcessed event, we will only publish it if isAsync == false
                    // async interactions that have failed, have their isAsync property modified to false above
                    // emit DefiBridgeProcessed(indexed bridgeId, indexed interactionNonce, totalInputValue, outputValueA, outputValueB, success)
                    {
                        mstore(mPtr, totalInputValue)
                        mstore(add(mPtr, 0x20), mload(bridgeResult)) // outputValueA
                        mstore(add(mPtr, 0x40), mload(add(bridgeResult, 0x20))) // outputValueB
                        mstore(add(mPtr, 0x60), mload(add(bridgeResult, 0x60))) // success
                        log3(mPtr, 0x80, DEFI_BRIDGE_PROCESSED_SIGHASH, bridgeId, interactionNonce)
                    }
                    // compute defiInteractionnHash
                    mstore(mPtr, bridgeId)
                    mstore(add(mPtr, 0x20), interactionNonce)
                    mstore(add(mPtr, 0x40), totalInputValue)
                    mstore(add(mPtr, 0x60), mload(bridgeResult)) // outputValueA
                    mstore(add(mPtr, 0x80), mload(add(bridgeResult, 0x20))) // outputValueB
                    mstore(add(mPtr, 0xa0), mload(add(bridgeResult, 0x60))) // success
                    pop(staticcall(gas(), 0x2, mPtr, 0xc0, 0x00, 0x20))
                    let defiInteractionHash := mod(mload(0x00), CIRCUIT_MODULUS)
                    // // defiInteractionHashes.push(defiInteractionHash) (don't update length, will do this outside of loop)
                    // // reentrancy attacks that modify defiInteractionHashes array should be ruled out because of reentrancyMutex
                    mstore(0x00, defiInteractionHashes.slot)
                    sstore(add(keccak256(0x00, 0x20), defiInteractionHashesLength), defiInteractionHash)
                    defiInteractionHashesLength := add(defiInteractionHashesLength, 0x01)
                }

                // advance interactionNonce and proofDataPtr
                interactionNonce := add(interactionNonce, 0x01)
                proofDataPtr := add(proofDataPtr, 0x20)
            }
        }

        assembly {
            /**
             * Cleanup
             *
             * 1. Copy asyncDefiInteractionHashes into defiInteractionHashes
             * 2. Update defiInteractionHashes.length
             * 2. Clear asyncDefiInteractionHashes.length
             * 3. Clear reentrancyMutex
             */
            let state := sload(rollupState.slot)

            let asyncDefiInteractionHashesLength := and(
                ARRAY_LENGTH_MASK,
                shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state)
            )

            // Validate we are not overflowing our 1024 array size
            let arrayOverflow := gt(
                add(asyncDefiInteractionHashesLength, defiInteractionHashesLength),
                ARRAY_LENGTH_MASK
            )

            // Throw an error if defiInteractionHashesLength > ARRAY_LENGTH_MASK (i.e. is >= 1024)
            // should never hit this! If block `i` generates synchronous txns,
            // block 'i + 1' must process them.
            // Only way this array size hits 1024 is if we produce a glut of async interaction results
            // between blocks. HOWEVER we ensure that async interaction callbacks fail iff they would increase
            // defiInteractionHashes length to be >= 512
            // Still, can't hurt to check...
            if arrayOverflow {
                // keccak256("ARRAY_OVERFLOW()")
                mstore(0x00, 0x58a4ab0e00000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }

            // copy async hashes into defiInteractionHashes
            mstore(0x00, defiInteractionHashes.slot)
            let defiSlotBase := add(keccak256(0x00, 0x20), defiInteractionHashesLength)
            mstore(0x00, asyncDefiInteractionHashes.slot)
            let asyncDefiSlotBase := keccak256(0x00, 0x20)
            for {
                let i := 0
            } lt(i, asyncDefiInteractionHashesLength) {
                i := add(i, 0x01)
            } {
                sstore(add(defiSlotBase, i), sload(add(asyncDefiSlotBase, i)))
            }

            // clear defiInteractionHashesLength in state
            state := and(not(shl(DEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)

            // write new defiInteractionHashesLength in state
            state := or(
                shl(
                    DEFIINTERACTIONHASHES_BIT_OFFSET,
                    add(asyncDefiInteractionHashesLength, defiInteractionHashesLength)
                ),
                state
            )

            // clear asyncDefiInteractionHashesLength in state
            state := and(not(shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)

            // write new state
            sstore(rollupState.slot, state)
        }

        // now we want to extract the next set of pending defi interaction hashes and calculate their hash to store for the next rollup
        (bytes32[] memory hashes, bytes32 nextExpectedHash) = calculateNextExpectedDefiHash();
        nextExpectedHashes = hashes;
        prevDefiInteractionsHash = nextExpectedHash;
    }

    /**
     * @dev Process asyncdefi interactions.
     *      Callback function for asynchronous bridge interactions.
     * @param interactionNonce - unique id of the interaection
     */
    function processAsyncDefiInteraction(uint256 interactionNonce) external override returns (bool) {
        // If the re-entrancy mutex is not set, set it!
        // The re-entrancy mutex guards against nested calls to `processRollup()` and deposit functions.
        bool startingMutexValue = getReentrancyMutex();
        if (!startingMutexValue) {
            setReentrancyMutex();
        }

        uint256 bridgeId;
        uint256 totalInputValue;
        assembly {
            mstore(0x00, interactionNonce)
            mstore(0x20, pendingDefiInteractions.slot)
            let interactionPtr := keccak256(0x00, 0x40)

            bridgeId := sload(interactionPtr)
            totalInputValue := sload(add(interactionPtr, 0x01))
        }
        if (bridgeId == 0) {
            revert INVALID_BRIDGE_ID();
        }
        BridgeData memory bridgeData = getBridgeData(bridgeId);

        (
            AztecTypes.AztecAsset memory inputAssetA,
            AztecTypes.AztecAsset memory inputAssetB,
            AztecTypes.AztecAsset memory outputAssetA,
            AztecTypes.AztecAsset memory outputAssetB
        ) = getAztecAssetTypes(bridgeData, interactionNonce);

        // Extract the bridge address from the bridgeId
        IDefiBridge bridgeContract;
        assembly {
            mstore(0x00, supportedBridges.slot)
            let bridgeSlot := keccak256(0x00, 0x20)

            bridgeContract := and(bridgeId, 0xffffffff)
            bridgeContract := sload(add(bridgeSlot, sub(bridgeContract, 0x01)))
            bridgeContract := and(bridgeContract, ADDRESS_MASK)
        }
        if (address(bridgeContract) == address(0)) {
            revert INVALID_BRIDGE_ADDRESS();
        }
        // Copy some variables to front of stack to get around stack too deep errors
        InteractionInputs memory inputs = InteractionInputs(
            totalInputValue,
            interactionNonce,
            uint64(bridgeData.auxData)
        );
        (uint256 outputValueA, uint256 outputValueB, bool interactionCompleted) = bridgeContract.finalise(
            inputAssetA,
            inputAssetB,
            outputAssetA,
            outputAssetB,
            inputs.interactionNonce,
            inputs.auxData
        );

        if (!interactionCompleted) {
            // clear the re-entrancy mutex if it was false at the start of this function
            if (!startingMutexValue) {
                clearReentrancyMutex();
            }
            return false;
        }

        // delete pendingDefiInteractions[interactionNonce]
        // N.B. only need to delete 1st slot value `bridgeId`. Deleting vars costs gas post-London
        // setting bridgeId to 0 is enough to cause future calls with this interaction nonce to fail
        pendingDefiInteractions[inputs.interactionNonce].bridgeId = 0;

        if (outputValueB > 0 && outputAssetB.assetType == AztecTypes.AztecAssetType.NOT_USED) {
            revert NONZERO_OUTPUT_VALUE_ON_NOT_USED_ASSET(outputValueB);
        }

        if (outputValueA == 0 && outputValueB == 0) {
            // issue refund.
            transferTokensAsync(address(bridgeContract), inputAssetA, inputs.totalInputValue, inputs.interactionNonce);
        } else {
            // transfer output tokens to rollup contract
            transferTokensAsync(address(bridgeContract), outputAssetA, outputValueA, inputs.interactionNonce);
            transferTokensAsync(address(bridgeContract), outputAssetB, outputValueB, inputs.interactionNonce);
        }

        // compute defiInteractionHash and push it onto the asyncDefiInteractionHashes array
        bool result;
        assembly {
            let inputValue := mload(inputs)
            let nonce := mload(add(inputs, 0x20))
            result := iszero(and(eq(outputValueA, 0), eq(outputValueB, 0)))
            let mPtr := mload(0x40)
            mstore(mPtr, bridgeId)
            mstore(add(mPtr, 0x20), nonce)
            mstore(add(mPtr, 0x40), inputValue)
            mstore(add(mPtr, 0x60), outputValueA)
            mstore(add(mPtr, 0x80), outputValueB)
            mstore(add(mPtr, 0xa0), result)
            pop(staticcall(gas(), 0x2, mPtr, 0xc0, 0x00, 0x20))
            let defiInteractionHash := mod(mload(0x00), CIRCUIT_MODULUS)

            // push async defi interaction hash
            mstore(0x00, asyncDefiInteractionHashes.slot)
            let slotBase := keccak256(0x00, 0x20)

            let state := sload(rollupState.slot)
            let asyncArrayLen := and(ARRAY_LENGTH_MASK, shr(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, state))
            let defiArrayLen := and(ARRAY_LENGTH_MASK, shr(DEFIINTERACTIONHASHES_BIT_OFFSET, state))

            // check that size of asyncDefiInteractionHashes isn't such that
            // adding 1 to it will make the next block's defiInteractionHashes length hit 512
            if gt(add(add(1, asyncArrayLen), defiArrayLen), 512) {
                // store keccak256("ARRAY_OVERFLOW()")
                // this code is equivalent to `revert ARRAY_OVERFLOW()`
                mstore(mPtr, 0x58a4ab0e00000000000000000000000000000000000000000000000000000000)
                revert(mPtr, 0x04)
            }

            // asyncDefiInteractionHashes.push(defiInteractionHash)
            sstore(add(slotBase, asyncArrayLen), defiInteractionHash)

            // update asyncDefiInteractionHashes.length by 1
            let oldState := and(not(shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, ARRAY_LENGTH_MASK)), state)
            let newState := or(oldState, shl(ASYNCDEFIINTERACTIONHASHES_BIT_OFFSET, add(asyncArrayLen, 0x01)))

            sstore(rollupState.slot, newState)
        }
        emit DefiBridgeProcessed(
            bridgeId,
            inputs.interactionNonce,
            inputs.totalInputValue,
            outputValueA,
            outputValueB,
            result
        );

        // clear the re-entrancy mutex if it was false at the start of this function
        if (!startingMutexValue) {
            clearReentrancyMutex();
        }
        return true;
    }

    /**
     * @dev Token transfer method used by processAsyncDefiInteraction
     * Calls `transferFrom` on the target erc20 token, if asset is of type ERC
     * If asset is ETH, we validate a payment has been made against the provided interaction nonce
     * @param bridgeContract address of bridge contract we're taking tokens from
     * @param asset the AztecAsset being transferred
     * @param outputValue the expected value transferred
     * @param interactionNonce the defi interaction nonce of the interaction
     */
    function transferTokensAsync(
        address bridgeContract,
        AztecTypes.AztecAsset memory asset,
        uint256 outputValue,
        uint256 interactionNonce
    ) internal {
        if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            if (outputValue > ethPayments[interactionNonce]) {
                revert INSUFFICIENT_ETH_TRANSFER();
            }
            ethPayments[interactionNonce] = 0;
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20 && outputValue > 0) {
            address tokenAddress = asset.erc20Address;
            TokenTransfers.safeTransferFrom(tokenAddress, bridgeContract, address(this), outputValue);
        }
    }

    /**
     * @dev Transfer a fee to the feeReceiver
     * @param proofData proof of knowledge of a rollup block update
     * @param feeReceiver fee beneficiary as described kby the rollup provider
     */
    function transferFee(bytes memory proofData, address feeReceiver) internal {
        for (uint256 i = 0; i < NUMBER_OF_ASSETS; ++i) {
            uint256 assetId = extractAssetId(proofData, i);
            uint256 txFee = extractTotalTxFee(proofData, i);
            if (txFee > 0) {
                if (assetId == ethAssetId) {
                    // We explicitly do not throw if this call fails, as this opens up the possiblity of
                    // griefing attacks, as engineering a failed fee will invalidate an entire rollup block
                    assembly {
                        pop(call(50000, feeReceiver, txFee, 0, 0, 0, 0))
                    }
                } else {
                    address assetAddress = getSupportedAsset(assetId);
                    TokenTransfers.transferToDoNotBubbleErrors(
                        assetAddress,
                        feeReceiver,
                        txFee,
                        assetGasLimits[assetId]
                    );
                }
            }
        }
    }

    /**
     * @dev Internal utility function to withdraw funds from the contract to a receiver address
     * @param withdrawValue - value being withdrawn from the contract
     * @param receiverAddress - address receiving public ERC20 tokens
     * @param assetId - ID of the asset for which a withdrawl is being performed
     */
    function withdraw(
        uint256 withdrawValue,
        address receiverAddress,
        uint256 assetId
    ) internal {
        validateAssetIdIsNotVirtual(assetId);
        if (receiverAddress == address(0)) {
            revert WITHDRAW_TO_ZERO_ADDRESS();
        }
        if (assetId == 0) {
            // We explicitly do not throw if this call fails, as this opens up the possiblity of
            // griefing attacks, as engineering a failed withdrawal will invalidate an entire rollup block
            assembly {
                pop(call(30000, receiverAddress, withdrawValue, 0, 0, 0, 0))
            }
            // payable(receiverAddress).call{gas: 30000, value: withdrawValue}('');
        } else {
            // We explicitly do not throw if this call fails, as this opens up the possiblity of
            // griefing attacks, as engineering a failed withdrawal will invalidate an entire rollup block
            // the user should ensure their withdrawal will succeed or they will loose funds
            address assetAddress = getSupportedAsset(assetId);
            TokenTransfers.transferToDoNotBubbleErrors(
                assetAddress,
                receiverAddress,
                withdrawValue,
                assetGasLimits[assetId]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

interface IVerifier {
    function verify(bytes memory serialized_proof, uint256 _publicInputsHash) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

interface IRollupProcessor {
    function defiBridgeProxy() external view returns (address);

    function offchainData(uint256 rollupId, bytes calldata offchainTxData) external;

    function processRollup(bytes calldata proofData, bytes calldata signatures) external;

    function depositPendingFunds(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash
    ) external payable;

    function depositPendingFundsPermit(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositPendingFundsPermitNonStandard(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setRollupProvider(address provderAddress, bool valid) external;

    function approveProof(bytes32 _proofHash) external;

    function pause() external;

    function setDefiBridgeProxy(address feeDistributorAddress) external;

    function setVerifier(address verifierAddress) external;

    function setSupportedAsset(address linkedToken, uint256 gasLimit) external;

    function setAllowThirdPartyContracts(bool _flag) external;

    function setSupportedBridge(address linkedBridge, uint256 gasLimit) external;

    function getSupportedAsset(uint256 assetId) external view returns (address);

    function getSupportedAssets() external view returns (address[] memory, uint256[] memory);

    function getSupportedBridge(uint256 bridgeAddressId) external view returns (address);

    function getBridgeGasLimit(uint256 bridgeAddressId) external view returns (uint256);

    function getSupportedBridges() external view returns (address[] memory, uint256[] memory);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function getUserPendingDeposit(uint256 assetId, address userAddress) external view returns (uint256);

    function processAsyncDefiInteraction(uint256 interactionNonce) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

interface IFeeDistributor {
    event FeeReimbursed(address receiver, uint256 amount);
    event Convert(address assetAddress, uint256 inputValue, uint256 outputValue);

    function convertConstant() external view returns (uint256);

    function feeLimit() external view returns (uint256);

    function aztecFeeClaimer() external view returns (address);

    function router() external view returns (address);

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function setFeeClaimer(address _feeClaimer) external;

    function setFeeLimit(uint256 _feeLimit) external;

    function setConvertConstant(uint256 _convertConstant) external;

    function txFeeBalance(address assetAddress) external view returns (uint256);

    function deposit(address assetAddress, uint256 amount) external payable returns (uint256 depositedAmount);

    function convert(address assetAddress, uint256 minOutputValue) external returns (uint256 outputValue);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Permit is IERC20 {
    function nonces(address user) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;
pragma experimental ABIEncoderV2;

import {AztecTypes} from '../AztecTypes.sol';

interface IDefiBridge {
    function convert(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    function canFinalise(uint256 interactionNonce) external view returns (bool);

    function finalise(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 interactionNonce,
        uint64 auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {Types} from './verifier/cryptography/Types.sol';
import {Bn254Crypto} from './verifier/cryptography/Bn254Crypto.sol';

/**
 * ----------------------------------------
 *  PROOF DATA SPECIFICATION
 * ----------------------------------------
 * Our input "proof data" is represented as a single byte array - we use a custom encoding the encode the
 * data associated with a rollup block. The encoded structure is as follows (excluding the length param of the bytes type):
 * 
   | byte range      | num bytes        | name                             | description |
   | ---             | ---              | ---                              | ---         |
   | 0x00  - 0x20    | 32               | rollupId                         | Unique rollup block identifier. Equivalent to block number |
   | 0x20  - 0x40    | 32               | rollupSize                       | Max number of transactions in the block |
   | 0x40  - 0x60    | 32               | dataStartIndex                   | Position of the next empty slot in the Aztec data tree |
   | 0x60  - 0x80    | 32               | oldDataRoot                      | Root of the data tree prior to rollup block's state updates |
   | 0x80  - 0xa0    | 32               | newDataRoot                      | Root of the data tree after rollup block's state updates |
   | 0xa0  - 0xc0    | 32               | oldNullRoot                      | Root of the nullifier tree prior to rollup block's state updates |
   | 0xc0  - 0xe0    | 32               | newNullRoot                      | Root of the nullifier tree after rollup block's state updates |
   | 0xe0  - 0x100   | 32               | oldDataRootsRoot                 | Root of the tree of data tree roots prior to rollup block's state updates |
   | 0x100 - 0x120   | 32               | newDataRootsRoot                 | Root of the tree of data tree roots after rollup block's state updates |
   | 0x120 - 0x140   | 32               | oldDefiRoot                      | Root of the defi tree prior to rollup block's state updates |
   | 0x140 - 0x160   | 32               | newDefiRoot                      | Root of the defi tree after rollup block's state updates |
   | 0x160 - 0x560   | 1024             | bridgeIds[NUMBER_OF_BRIDGE_CALLS]   | Size-32 array of bridgeIds for bridges being called in this block. If bridgeId == 0, no bridge is called |
   | 0x560 - 0x960   | 1024             | depositSums[NUMBER_OF_BRIDGE_CALLS] | Size-32 array of deposit values being sent for bridges being called in this block |
   | 0x960 - 0xb60   | 512              | assetIds[NUMBER_OF_ASSETS]         | Size-16 array of the assetIds for assets being deposited/withdrawn/used to pay fees in this block |
   | 0xb60 - 0xd60   | 512              | txFees[NUMBER_OF_ASSETS]           | Size-16 array of transaction fees paid to the rollup beneficiary, denominated in each assetId |
   | 0xd60 - 0x1160  | 1024             | interactionNotes[NUMBER_OF_BRIDGE_CALLS] | Size-32 array of defi interaction result commitments that must be inserted into the defi tree at this rollup block |
   | 0x1160 - 0x1180 | 32               | prevDefiInteractionHash          | A SHA256 hash of the data used to create each interaction result commitment. Used to validate correctness of interactionNotes |
   | 0x1180 - 0x11a0 | 32               | rollupBeneficiary                | The address that the fees from this rollup block should be sent to. Prevents a rollup proof being taken from the transaction pool and having its fees redirected |
   | 0x11a0 - 0x11c0 | 32               | numRollupTxs                     | Number of "inner rollup" proofs used to create the block proof. "inner rollup" circuits process 3-28 user txns, the outer rollup circuit processes 1-28 inner rollup proofs. |
   | 0x11c0 - 0x11c4 | 4                | numRealTxs                       | Number of transactions in the rollup excluding right-padded padding proofs
   | 0x11c4 - 0x11c8 | 4                | encodedInnerTxData.length        | Number of bytes of encodedInnerTxData |
   | 0x11c8 - end    | encodedInnerTxData.length | encodedInnerTxData      | Encoded inner transaction data. Contains encoded form of the broadcasted data associated with each tx in the rollup block |
 **/

 /**
  * --------------------------------------------
  *  DETERMINING THE NUMBER OF REAL TRANSACTIONS
  * --------------------------------------------
  * The `rollupSize` parameter describes the MAX number of txns in a block.
  * However the block may not be full.
  * Incomplete blocks will be padded with "padding" transactions that represent empty txns.
  *
  * The amount of end padding is not explicitly defined in `proofData`. It is derived.
  * The encodedInnerTxData does not include tx data for the txns associated with this end padding.
  * (it does include any padding transactions that are not part of the end padding, which can sometimes happen)
  * When decoded, the transaction data for each transaction is a fixed size (256 bytes)
  * Number of real transactions = rollupSize - (decoded tx data size / 256)
  *
  * The decoded transaction data associated with padding transactions is 256 zero bytes.
 **/

/**
 * @title Decoder
 * @dev contains functions for decoding/extracting the encoded proof data passed in as calldata,
 * as well as computing the SHA256 hash of the decoded data (publicInputsHash).
 * The publicInputsHash is used to ensure the data passed in as calldata matches the data used within the rollup circuit
 */
contract Decoder {

    /*----------------------------------------
      CONSTANTS
      ----------------------------------------*/
    uint256 internal constant NUMBER_OF_ASSETS = 16; // max number of assets in a block
    uint256 internal constant NUMBER_OF_BRIDGE_CALLS = 32; // max number of bridge calls in a block
    uint256 internal constant NUMBER_OF_BRIDGE_BYTES = 1024; // NUMBER_OF_BRIDGE_CALLS * 32
    uint256 internal constant NUMBER_OF_PUBLIC_INPUTS_PER_TX = 8; // number of ZK-SNARK "public inputs" per join-split/account/claim transaction
    uint256 internal constant TX_PUBLIC_INPUT_LENGTH = 256; // byte-length of NUMBER_OF_PUBLIC_INPUTS_PER_TX. NUMBER_OF_PUBLIC_INPUTS_PER_TX * 32;
    uint256 internal constant ROLLUP_NUM_HEADER_INPUTS = 142; // 58; // number of ZK-SNARK "public inputs" that make up the rollup header 14 + (NUMBER_OF_BRIDGE_CALLS * 3) + (NUMBER_OF_ASSETS * 2);
    uint256 internal constant ROLLUP_HEADER_LENGTH = 4544; // 1856; // ROLLUP_NUM_HEADER_INPUTS * 32;

    // ENCODED_PROOF_DATA_LENGTH_OFFSET = byte offset into the rollup header such that `numRealTransactions` occupies
    // the least significant 4 bytes of the 32-byte word being pointed to.
    // i.e. ROLLUP_HEADER_LENGTH - 28
    uint256 internal constant NUM_REAL_TRANSACTIONS_OFFSET = 4516;

    // ENCODED_PROOF_DATA_LENGTH_OFFSET = byte offset into the rollup header such that `encodedInnerProofData.length` occupies
    // the least significant 4 bytes of the 32-byte word being pointed to.
    // i.e. ROLLUP_HEADER_LENGTH - 24
    uint256 internal constant ENCODED_PROOF_DATA_LENGTH_OFFSET = 4520;

    // offset we add to `proofData` to point to the bridgeIds
    uint256 internal constant BRIDGE_IDS_OFFSET = 0x180;

    // offset we add to `proofData` to point to prevDefiInteractionhash
    uint256 internal constant PREVIOUS_DEFI_INTERACTION_HASH_OFFSET = 4480; // ROLLUP_HEADER_LENGTH - 0x40

    // offset we add to `proofData` to point to rollupBeneficiary
    uint256 internal constant ROLLUP_BENEFICIARY_OFFSET = 4512; // ROLLUP_HEADER_LENGTH - 0x20

    // CIRCUIT_MODULUS = group order of the BN254 elliptic curve. All arithmetic gates in our ZK-SNARK circuits are evaluated modulo this prime.
    // Is used when computing the public inputs hash - our SHA256 hash outputs are reduced modulo CIRCUIT_MODULUS
    uint256 internal constant CIRCUIT_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // SHA256 hashes
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_1 =
        0x22dd983f8337d97d56071f7986209ab2ee6039a422242e89126701c6ee005af0;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_2 =
        0x076a27c79e5ace2a3d47f9dd2e83e4ff6ea8872b3c2218f66c92b89b55f36560;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_4 =
        0x2f0c70a5bf5460465e9902f9c96be324e8064e762a5de52589fdb97cbce3c6ee;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_8 =
        0x240ed0de145447ff0ceff2aa477f43e0e2ed7f3543ee3d8832f158ec76b183a9;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_16 =
        0x1c52c159b4dae66c3dcf33b44d4d61ead6bc4d260f882ac6ba34dccf78892ca4;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_32 =
        0x0df0e06ab8a02ce2ff08babd7144ab23ca2e99ddf318080cf88602eeb8913d44;
    uint256 internal constant PADDING_ROLLUP_HASH_SIZE_64 =
        0x1f83672815ac9b3ca31732d641784035834e96b269eaf6a2e759bf4fcc8e5bfd;

    uint256 internal constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;

    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error ENCODING_BYTE_INVALID();
    error INVALID_ROLLUP_TOPOLOGY();

    /*----------------------------------------
      DECODING FUNCTIONS
      ----------------------------------------*/
    /**
     * In `bytes proofData`, transaction data is appended after the rollup header data
     * Each transaction is described by 8 'public inputs' used to create a user transaction ZK-SNARK proof
     * (i.e. there are 8 public inputs for each of the "join-split", "account" and "claim" circuits)
     * The public inputs are represented in calldata according to the following specification:
     *
     * | public input idx | calldata size (bytes) | variable | description |
     * | 0                | 1                     |proofId         | transaction type identifier       |
     * | 1                | 32                    | encrypted form of 1st output note |
     * | 2                | 32                    | encrypted form of 2nd output note |
     * | 3                | 32                    | nullifier of 1st input note       |
     * | 4                | 32                    | nullifier of 2nd input note       |
     * | 5                | 32                    | amount being deposited or withdrawn |
     * | 6                | 20                    | address of depositor or withdraw destination |
     * | 7                | 4                     | assetId used in transaction |
     *
     * The following table maps proofId values to transaction types
     *
     *
     * | proofId | tx type     | description |
     * | ---     | ---         | ---         |
     * | 0       | padding     | empty transaction. Rollup blocks have a fixed number of txns. If number of real txns is less than block size, padding txns make up the difference |
     * | 1       | deposit     | deposit Eth/tokens into Aztec in exchange for encrypted Aztec notes |
     * | 2       | withdraw    | exchange encrypted Aztec notes for Eth/tokens sent to a public address |
     * | 3       | send        | private send |
     * | 4       | account     | creates an Aztec account |
     * | 5       | defiDeposit | deposit Eth/tokens into a L1 smart contract via a Defi bridge contract |
     * | 6       | defiClaim   | convert proceeds of defiDeposit tx back into encrypted Aztec notes |
     *
     * Most of the above transaction types do not use the full set of 8 public inputs (i.e. some are zero).
     * To save on calldata costs, we encode each transaction into the smallest payload possible.
     * In `decodeProof`, the encoded transaction data decoded, with the decoded tx data written into memory
     *
     * As part of the decoding algorithms we must convert the 20-byte `publicOwner` and 4-byte `assetId` fields
     * into 32-byte EVM words
     *
     * The following functions perform transaction-specific decoding. The `proofId` field is decoded prior to calling these functions
     */

    /**
     * @dev decode a padding tx
     * @param inPtr location in calldata of the encoded transaction
     * @return location in calldata of the next encoded transaction
     *
     * Encoded padding tx consists of 1 byte, the `proofId`
     * The proofId has been written into memory before we called this function so there is nothing to copy.
     * Advance the calldatapointer by 1 byte to move to the next transaction
     */
    function paddingTx(uint256 inPtr, uint256) internal pure returns (uint256) {
        return (inPtr + 0x1);
    }

    /**
     * @dev decode a deposit or a withdraw tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * the deposit tx uses all 8 public inputs. All calldata is copied into memory
     */
    function depositOrWithdrawTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        // Copy deposit calldata into memory
        assembly {
            // start copying into `outPtr + 0x20`, as `outPtr` points to `proofId`, which has already been written into memry
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0xa0) // noteCommitment1 ... publicValue
            calldatacopy(add(outPtr, 0xcc), add(inPtr, 0xc0), 0x14) // convert 20-byte publicOwner calldata variable into 32-byte EVM word
            calldatacopy(add(outPtr, 0xfc), add(inPtr, 0xd4), 0x4) // convert 4-byte assetId variable into 32-byte EVM word
        }
        // advance calldata ptr by 185 bytes
        unchecked {
            return (inPtr + 0xb9);
        }
    }

    /**
     * @dev decode a send tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The send tx has 0-values for `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function sendTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x80) // noteCommitment1 ... nullifier2
        }
        unchecked {
            return (inPtr + 0x81);
        }
    }

    /**
     * @dev decode an account tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The send tx has 0-values for `nullifier2`, `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function accountTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x60) // noteCommitment1 ... nullifier1
        }
        unchecked {
            return (inPtr + 0x61);
        }
    }

    /**
     * @dev decode a defi deposit or claim tx
     * @param inPtr location in calldata of the encoded transaction
     * @param outPtr location in memory to write the decoded transaction to
     * @return location in calldata of the next encoded transaction
     *
     * The defi deposit/claim txns has 0-values for `publicValue`, `publicOwner` and `assetId`
     * No need to copy anything into memory for these fields as memory defaults to 0
     */
    function defiDepositOrClaimTx(uint256 inPtr, uint256 outPtr) internal pure returns (uint256) {
        assembly {
            calldatacopy(add(outPtr, 0x20), add(inPtr, 0x20), 0x80) // noteCommitment1 ... nullifier2
        }
        unchecked {
            return (inPtr + 0x81);
        }
    }

    /**
     * @dev invalid transaction function
     * If we hit this, there is a transaction whose proofId is invalid (i.e. not 0 to 7).
     * Throw an error and revert the tx.
     */
    function invalidTx(uint256, uint256) internal pure returns (uint256) {
        revert ENCODING_BYTE_INVALID();
    }

    /**
     * @dev decodes the rollup block's proof data
     * This function converts the proof data into a representation we can work with in memory
     * In particular, encoded transaction calldata is decoded and written into memory
     * The rollup header is also copied from calldata into memory
     * @return proofData numTxs publicInputsHash
     * proofData is a memory pointer to the decoded proof data
     *
     * The publicInputsHash is a sha256 hash of the public inputs associated with each transaction in the rollup.
     * It is used to validate the correctness of the data being fed into the rollup circuit
     * (there is a bit of nomenclature abuse here. Processing a public input in the verifier algorithm costs 150 gas, which
     * adds up very quickly. Instead of this, we sha256 hash what used to be the "public" inputs and only set the hash to be public.
     * We then make the old "public" inputs private in the rollup circuit, and validate their correctness by checking their sha256 hash matches
     * what we compute in the decodeProof function!
     *
     * numTxs = number of transactions in the rollup, excluding end-padding transactions
     * 
     */
    function decodeProof()
        internal
        view
        returns (
            bytes memory proofData,
            uint256 numTxs,
            uint256 publicInputsHash
        )
    {
        // declare some variables that will be set inside asm blocks
        uint256 dataSize; // size of our decoded transaction data, in bytes
        uint256 outPtr; // memory pointer to where we will write our decoded transaction data
        uint256 inPtr; // calldata pointer into our proof data
        uint256 rollupSize; // max number of transactions in the rollup block
        uint256 decodedTxDataStart;

        {
            uint256 tailInPtr; // calldata pointer to the end of our proof data

            /**
             * Let's build a function table!
             *
             * To decode our tx data, we need to iterate over every encoded transaction and call its
             * associated decoding function. If we did this via a `switch` statement this would be VERY expensive,
             * due to the large number of JUMPI instructions that would be called.
             *
             * Instead, we use function pointers.
             * The `proofId` field in our encoded proof data is an integer from 0-6,
             * we can use `proofId` to index a table of function pointers for our respective decoding functions.
             * This is much faster as there is no conditional branching!
             */
            function(uint256, uint256) pure returns (uint256) callfunc; // we're going to use `callfunc` as a function pointer
            // `functionTable` is a pointer to a table in memory, containing function pointers
            // Step 1: reserve memory for functionTable
            uint256 functionTable;
            assembly {
                functionTable := mload(0x40)
                mstore(0x40, add(functionTable, 0x100)) // reserve 256 bytes for function pointers
            }
            {
                // Step 2: copy function pointers into local variables so that inline asm code can access them
                function(uint256, uint256) pure returns (uint256) t0 = paddingTx;
                function(uint256, uint256) pure returns (uint256) t1 = depositOrWithdrawTx;
                function(uint256, uint256) pure returns (uint256) t3 = sendTx;
                function(uint256, uint256) pure returns (uint256) t4 = accountTx;
                function(uint256, uint256) pure returns (uint256) t5 = defiDepositOrClaimTx;
                function(uint256, uint256) pure returns (uint256) t7 = invalidTx;

                // Step 3: write function pointers into the table!
                assembly {
                    mstore(functionTable, t0)
                    mstore(add(functionTable, 0x20), t1)
                    mstore(add(functionTable, 0x40), t1)
                    mstore(add(functionTable, 0x60), t3)
                    mstore(add(functionTable, 0x80), t4)
                    mstore(add(functionTable, 0xa0), t5)
                    mstore(add(functionTable, 0xc0), t5)
                    mstore(add(functionTable, 0xe0), t7) // a proofId of 7 is not a valid transaction type, set to invalidTx
                }
            }
            uint256 decodedTransactionDataSize;
            assembly {
                // Add encoded proof data size to dataSize, minus the 4 bytes of encodedInnerProofData.length.
                // Set inPtr to point to the length parameter of `bytes calldata proofData`
                inPtr := add(calldataload(0x04), 0x4) // `proofData = first input parameter. Calldata offset to proofData will be at 0x04. Add 0x04 to account for function signature.
                
                // set dataSize to be the length of `bytes calldata proofData`
                // dataSize := sub(calldataload(inPtr), 0x4)

                // Advance inPtr to point to the start of proofData
                inPtr := add(inPtr, 0x20)

                numTxs := and(
                    calldataload(add(inPtr, NUM_REAL_TRANSACTIONS_OFFSET)),
                    0xffffffff
                )
                // Get encoded inner proof data size.
                // add ENCODED_PROOF_DATA_LENGTH_OFFSET to inPtr to point to the correct variable in our header block,
                // mask off all but 4 least significant bytes as this is a packed 32-bit variable.
                let encodedInnerDataSize := and(
                    calldataload(add(inPtr, ENCODED_PROOF_DATA_LENGTH_OFFSET)),
                    0xffffffff
                )
                // Add the size of trimmed zero bytes to dataSize.

                // load up the rollup size from `proofData`
                rollupSize := calldataload(add(inPtr, 0x20))

                // compute the number of bytes our decoded proof data will take up.
                // i.e. num total txns in the rollup (including padding) * number of public inputs per transaction
                let decodedInnerDataSize := mul(rollupSize, TX_PUBLIC_INPUT_LENGTH)

                // we want dataSize to equal: rollup header length + decoded tx length (excluding padding blocks)
                let numInnerRollups := calldataload(add(inPtr, sub(ROLLUP_HEADER_LENGTH, 0x20)))
                let numTxsPerRollup := div(rollupSize, numInnerRollups)

                let numFilledBlocks := div(numTxs, numTxsPerRollup)
                numFilledBlocks := add(numFilledBlocks, iszero(eq(mul(numFilledBlocks, numTxsPerRollup), numTxs)))

                decodedTransactionDataSize := mul(mul(numFilledBlocks, numTxsPerRollup), TX_PUBLIC_INPUT_LENGTH)
                // i.e. current dataSize value + (difference between decoded and encoded data)
                dataSize := add(ROLLUP_HEADER_LENGTH, decodedTransactionDataSize)

                // Allocate memory for `proofData`.
                proofData := mload(0x40)
                // set free mem ptr to dataSize + 0x20 (to account for the 0x20 bytes for the length param of proofData)
                // This allocates memory whose size is equal to the rollup header size, plus the data required for
                // each transaction's decoded tx data (256 bytes * number of non-padding blocks)
                // only reserve memory for blocks that contain non-padding proofs. These "padding" blocks don't need to be
                // stored in memory as we don't need their data for any computations
                mstore(0x40, add(proofData, add(dataSize, 0x20)))

                // set outPtr to point to the proofData length parameter
                outPtr := proofData
                // write dataSize into proofData.length
                mstore(outPtr, dataSize)
                // advance outPtr to point to start of proofData
                outPtr := add(outPtr, 0x20)

                // Copy rollup header data to `proofData`.
                calldatacopy(outPtr, inPtr, ROLLUP_HEADER_LENGTH)
                // Advance outPtr to point to the end of the header data (i.e. the start of the decoded inner transaction data)
                outPtr := add(outPtr, ROLLUP_HEADER_LENGTH)

                // Advance inPtr to point to the start of our encoded inner transaction data.
                // Add (ROLLUP_HEADER_LENGTH + 0x08) to skip over the packed (numRealTransactions, encodedProofData.length) parameters
                inPtr := add(inPtr, add(ROLLUP_HEADER_LENGTH, 0x08))

                // Set tailInPtr to point to the end of our encoded transaction data
                tailInPtr := add(inPtr, encodedInnerDataSize)
                // Set decodedTxDataStart pointer
                decodedTxDataStart := outPtr
            }
            /**
             * Start of decoding algorithm
             *
             * Iterate over every encoded transaction, load out the first byte (`proofId`) and use it to
             * jump to the relevant transaction's decoding function
             */
            assembly {
                // subtract 31 bytes off of inPtr, so that the first byte of the encoded transaction data
                // is located at the least significant byte of calldataload(inPtr)
                // also adjust tailInPtr as we compare inPtr against tailInPtr
                inPtr := sub(inPtr, 0x1f)
                tailInPtr := sub(tailInPtr, 0x1f)
            }
            unchecked {
                for (; tailInPtr > inPtr; ) {
                    assembly {
                        // For each tx, the encoding byte determines how we decode the tx calldata
                        // The encoding byte can take values from 0 to 7; we want to turn these into offsets that can index our function table.
                        // 1. Access encoding byte via `calldataload(inPtr)`. The least significant byte is our encoding byte. Mask off all but the 3 least sig bits
                        // 2. Shift left by 5 bits. This is equivalent to multiplying the encoding byte by 32.
                        // 4. The result will be 1 of 8 offset values (0x00, 0x20, ..., 0xe0) which we can use to retrieve the relevant function pointer from `functionTable`
                        let encoding := and(calldataload(inPtr), 7)
                        // store proofId at outPtr.
                        mstore(outPtr, encoding) // proofId

                        // use proofId to extract the relevant function pointer from functionTable
                        callfunc := mload(add(functionTable, shl(5, encoding)))
                    }
                    // call the decoding function. Return value will be next required value of inPtr
                    inPtr = callfunc(inPtr, outPtr);
                    // advance outPtr by the size of a decoded transaction
                    outPtr += TX_PUBLIC_INPUT_LENGTH;
                }
            }
        }

        /**
         * Compute the public inputs hash
         *
         * We need to take our decoded proof data and compute its SHA256 hash.
         * This hash is fed into our rollup proof as a public input.
         * If the hash does not match the SHA256 hash computed within the rollup circuit
         * on the equivalent parameters, the proof will reject.
         * This check ensures that the transaction data present in calldata are equal to
         * the transaction data values present in the rollup ZK-SNARK circuit.
         *
         * One complication is the structure of the SHA256 hash.
         * We slice transactions into chunks equal to the number of transactions in the "inner rollup" circuit
         * (a rollup circuit verifies multiple "inner rollup" circuits, which each verify 3-28 private user transactions.
         *  This tree structure helps parallelise proof construction)
         * We then SHA256 hash each transaction *chunk*
         * Finally we SHA256 hash the above SHA256 hashes to get our public input hash!
         *
         * We do the above instead of a straight hash of all of the transaction data,
         * because it's faster to parallelise proof construction if the majority of the SHA256 hashes are computed in
         * the "inner rollup" circuit and not the main rollup circuit.
         */
        // Step 1: compute the hashes that constitute the inner proofs data
        bool invalidRollupTopology;
        assembly {
            // we need to figure out how many rollup proofs are in this tx and how many user transactions are in each rollup
            let numRollupTxs := mload(add(proofData, ROLLUP_HEADER_LENGTH))
            let numJoinSplitsPerRollup := div(rollupSize, numRollupTxs)
            let rollupDataSize := mul(mul(numJoinSplitsPerRollup, NUMBER_OF_PUBLIC_INPUTS_PER_TX), 32)

            // Compute the number of inner rollups that don't contain padding proofs
            let numNotEmptyInnerRollups := div(numTxs, numJoinSplitsPerRollup)
            numNotEmptyInnerRollups := add(
                numNotEmptyInnerRollups,
                iszero(eq(mul(numNotEmptyInnerRollups, numJoinSplitsPerRollup), numTxs))
            )
            // Compute the number of inner rollups that only contain padding proofs!
            // For these "empty" inner rollups, we don't need to compute their public inputs hash directly,
            // we can use a precomputed value
            let numEmptyInnerRollups := sub(numRollupTxs, numNotEmptyInnerRollups)

            let proofdataHashPtr := mload(0x40)
            // copy the header data into the proofdataHash
            // header start is at calldataload(0x04) + 0x24 (+0x04 to skip over func signature, +0x20 to skip over byte array length param)
            calldatacopy(proofdataHashPtr, add(calldataload(0x04), 0x24), ROLLUP_HEADER_LENGTH)

            // update pointer
            proofdataHashPtr := add(proofdataHashPtr, ROLLUP_HEADER_LENGTH)

            // compute the endpoint for the proofdataHashPtr (used as a loop boundary condition)
            let endPtr := add(proofdataHashPtr, mul(numNotEmptyInnerRollups, 0x20))
            // iterate over the public inputs for each inner rollup proof and compute their SHA256 hash

            // better solution here is ... iterate over number of non-padding rollup blocks
            // and hash those
            // for padding rollup blocks...just append the zero hash
            for {

            } lt(proofdataHashPtr, endPtr) {
                proofdataHashPtr := add(proofdataHashPtr, 0x20)
            } {
                // address(0x02) is the SHA256 precompile address
                if iszero(staticcall(gas(), 0x02, decodedTxDataStart, rollupDataSize, 0x00, 0x20)) {
                    revert(0x00, 0x00)
                }

                mstore(proofdataHashPtr, mod(mload(0x00), CIRCUIT_MODULUS))
                decodedTxDataStart := add(decodedTxDataStart, rollupDataSize)
            }

            // If there are empty inner rollups, we can use a precomputed hash
            // of their public inputs instead of computing it directly.
            if iszero(iszero(numEmptyInnerRollups))
            {
                let zeroHash
                switch numJoinSplitsPerRollup
                case 32 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_32
                }
                case 16 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_16
                }
                case 64 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_64
                }
                case 1 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_1
                }
                case 2 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_2
                }
                case 4 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_4
                }
                case 8 {
                    zeroHash := PADDING_ROLLUP_HASH_SIZE_8
                }
                default {
                    invalidRollupTopology := true
                }
    
                endPtr := add(endPtr, mul(numEmptyInnerRollups, 0x20))
                for {

                } lt (proofdataHashPtr, endPtr) {
                    proofdataHashPtr := add(proofdataHashPtr, 0x20)
                } {
                    mstore(proofdataHashPtr, zeroHash)
                }
            }
            // compute SHA256 hash of header data + inner public input hashes
            let startPtr := mload(0x40)
            if iszero(staticcall(gas(), 0x02, startPtr, sub(proofdataHashPtr, startPtr), 0x00, 0x20)) {
                revert(0x00, 0x00)
            }
            publicInputsHash := mod(mload(0x00), CIRCUIT_MODULUS)
        }
        if (invalidRollupTopology)
        {
            revert INVALID_ROLLUP_TOPOLOGY();
        }
    }

    /**
     * @dev Extract the `rollupId` param from the decoded proof data.
     * represents the rollupId of the next valid rollup block
     * @param proofData the decoded proof data
     * @return nextRollupId the expected id of the next rollup block
     */
    function getRollupId(bytes memory proofData) internal pure returns (uint256 nextRollupId) {
        assembly {
            nextRollupId := mload(add(proofData, 0x20))
        }
    }

    /**
     * @dev Decode the public inputs component of proofData and compute sha3 hash of merkle roots && dataStartIndex
     *      The rollup's state is uniquely defined by the following variables:
     *          * The next empty location in the data root tree (rollupId + 1)
     *          * The next empty location in the data tree (dataStartIndex + rollupSize)
     *          * The root of the data tree
     *          * The root of the nullifier set
     *          * The root of the data root tree (tree containing all previous roots of the data tree)
     *          * The root of the defi tree
     *      Instead of storing all of these variables in storage (expensive!), we store a keccak256 hash of them.
     *      To validate the correctness of a block's state transition, we must perform the following:
     *          * Use proof broadcasted inputs to reconstruct the "old" state hash
     *          * Use proof broadcasted inputs to reconstruct the "new" state hash
     *          * Validate the old state hash matches what is in storage
     *          * Set the old state hash to the new state hash
     *      N.B. we still store dataSize as a separate storage var as proofData does not contain all
     *           neccessary information to reconstruct its old value.
     * @param proofData - cryptographic proofData associated with a rollup
     */
    function computeRootHashes(bytes memory proofData)
        internal
        pure
        returns (
            uint256 rollupId,
            bytes32 oldStateHash,
            bytes32 newStateHash,
            uint32 numDataLeaves,
            uint32 dataStartIndex
        )
    {
        assembly {
            let dataStart := add(proofData, 0x20) // jump over first word, it's length of data
            numDataLeaves := shl(1, mload(add(dataStart, 0x20))) // rollupSize * 2 (2 notes per tx)
            dataStartIndex := mload(add(dataStart, 0x40))

            // validate numDataLeaves && dataStartIndex are uint32s
            if or(gt(numDataLeaves, 0xffffffff), gt(dataStartIndex, 0xffffffff))
            {
                revert(0,0)
            }
            rollupId := mload(dataStart)

            let mPtr := mload(0x40)

            mstore(mPtr, rollupId) // old nextRollupId
            mstore(add(mPtr, 0x20), mload(add(dataStart, 0x60))) // oldDataRoot
            mstore(add(mPtr, 0x40), mload(add(dataStart, 0xa0))) // oldNullRoot
            mstore(add(mPtr, 0x60), mload(add(dataStart, 0xe0))) // oldRootRoot
            mstore(add(mPtr, 0x80), mload(add(dataStart, 0x120))) // oldDefiRoot
            oldStateHash := keccak256(mPtr, 0xa0)

            mstore(mPtr, add(rollupId, 0x01)) // new nextRollupId
            mstore(add(mPtr, 0x20), mload(add(dataStart, 0x80))) // newDataRoot
            mstore(add(mPtr, 0x40), mload(add(dataStart, 0xc0))) // newNullRoot
            mstore(add(mPtr, 0x60), mload(add(dataStart, 0x100))) // newRootRoot
            mstore(add(mPtr, 0x80), mload(add(dataStart, 0x140))) // newDefiRoot
            newStateHash := keccak256(mPtr, 0xa0)
        }
    }

    /**
     * @dev extract the `prevDefiInterationHash` from the proofData's rollup header
     * @param proofData byte array of our input proof data
     * @return prevDefiInteractionHash the defiInteractionHash of the previous rollup block
     */
    function extractPrevDefiInteractionHash(bytes memory proofData)
        internal
        pure
        returns (bytes32 prevDefiInteractionHash)
    {
        assembly {
            prevDefiInteractionHash := mload(add(proofData, PREVIOUS_DEFI_INTERACTION_HASH_OFFSET))
        }
    }

    /**
     * @dev extract the address we pay the rollup fee to, from the proofData's rollup header
     * This "rollup beneficiary" address is included as part of the ZK-SNARK circuit data, so that
     * the rollup provider can explicitly define who should get the fee at the point they generate the ZK-SNARK proof.
     * (instead of simply sending the fee to msg.sender)
     * This prevents front-running attacks where an attacker can take somebody else's rollup proof from out of the tx pool and replay it, stealing the fee.
     * @param proofData byte array of our input proof data
     * @return rollupBeneficiaryAddress the address we pay this rollup block's fee to
     */
    function extractRollupBeneficiaryAddress(bytes memory proofData)
        internal
        pure
        returns (address rollupBeneficiaryAddress)
    {
        assembly {
            rollupBeneficiaryAddress := mload(add(proofData, ROLLUP_BENEFICIARY_OFFSET))
            // validate rollupBeneficiaryAddress is an address!
            if gt(rollupBeneficiaryAddress, ADDRESS_MASK) {
                revert(0, 0)
            }

        }
    }

    /**
     * @dev Extract an assetId from the rollup block.
     * The rollup block contains up to 16 different assets, which can be recovered from the rollup header data.
     * @param proofData byte array of our input proof data
     * @param idx The index of the asset we want. assetId = header.assetIds[idx]
     * @return assetId the 30-bit identifier of an asset. The ERC20 token address is obtained via the mapping `supportedAssets[assetId]`, 
     */
    function extractAssetId(
        bytes memory proofData,
        uint256 idx
    ) internal pure returns (uint256 assetId) {
        assembly {
            assetId := mload(add(add(add(proofData, BRIDGE_IDS_OFFSET), mul(0x40, NUMBER_OF_BRIDGE_CALLS)), mul(0x20, idx)))
            // validate assetId is a uint32!
            if gt(assetId, 0xffffffff) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Extract the transaction fee, for a given asset, due to be paid to the rollup beneficiary
     * The total fee is the sum of the individual fees paid by each transaction in the rollup block.
     * This sum is computed directly in the rollup circuit, and is present in the rollup header data
     * @param proofData byte array of our input proof data
     * @param idx The index of the asset the fee is denominated in
     * @return totalTxFee 
     */
    function extractTotalTxFee(
        bytes memory proofData,
        uint256 idx
    ) internal pure returns (uint256 totalTxFee) {
        assembly {
            totalTxFee := mload(add(add(add(proofData, 0x380), mul(0x40, NUMBER_OF_BRIDGE_CALLS)), mul(0x20, idx)))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

/**
 * @title TokenTransfers
 * @dev Provides functions to safely call `transfer` and `transferFrom` methods on ERC20 tokens,
 * as well as the ability to call `transfer` and `transferFrom` without bubbling up errors
 */
library TokenTransfers {
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb; // bytes4(keccak256('transfer(address,uint256)'));
    bytes4 private constant TRANSFER_FROM_SELECTOR = 0x23b872dd; // bytes4(keccak256('transferFrom(address,address,uint256)'));

    /**
     * @dev Safely call ERC20.transfer, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending tokens to?
     * @param amount How many tokens are we transferring?
     */
    function safeTransferTo(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        // The ERC20 token standard states that:
        // 1. failed transfers must throw
        // 2. the result of the transfer (success/fail) is returned as a boolean
        // Some token contracts don't implement the spec correctly and will do one of the following:
        // 1. Contract does not throw if transfer fails, instead returns false
        // 2. Contract throws if transfer fails, but does not return any boolean value
        // We can check for these by evaluating the following:
        // | call succeeds? (c) | return value (v) | returndatasize == 0 (r)| interpreted result |
        // | ---                | ---              | ---                    | ---                |
        // | false              | false            | false                  | transfer fails     |
        // | false              | false            | true                   | transfer fails     |
        // | false              | true             | false                  | transfer fails     |
        // | false              | true             | true                   | transfer fails     |
        // | true               | false            | false                  | transfer fails     |
        // | true               | false            | true                   | transfer succeeds  |
        // | true               | true             | false                  | transfer succeeds  |
        // | true               | true             | true                   | transfer succeeds  |
        //
        // i.e. failure state = !(c && (r || v))
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            let call_success := call(gas(), tokenAddress, 0, ptr, 0x44, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Safely call ERC20.transferFrom, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     */
    function safeTransferFrom(
        address tokenAddress,
        address source,
        address target,
        uint256 amount
    ) internal {
        assembly {
            // call tokenAddress.transferFrom(source, target, value)
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            let call_success := call(gas(), tokenAddress, 0, mPtr, 0x64, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transfer(to, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferToDoNotBubbleErrors(
        address tokenAddress,
        address to,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            pop(call(callGas, tokenAddress, 0, ptr, 0x44, 0x00, 0x00))
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transferFrom(source, target, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferFromDoNotBubbleErrors(
        address tokenAddress,
        address source,
        address target,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            pop(call(callGas, tokenAddress, 0, mPtr, 0x64, 0x00, 0x00))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4 <0.8.11;

library RollupProcessorLibrary {
    error SIGNATURE_ADDRESS_IS_ZERO();
    error SIGNATURE_RECOVERY_FAILED();
    error INVALID_SIGNATURE();

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * @param digest - Hashed data being signed over.
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateSignature(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }

        // prepend "\x19Ethereum Signed Message:\n32" to the digest to create the signed message
        bytes32 message;
        assembly {
            mstore(0, '\x19Ethereum Signed Message:\n32')
            mstore(add(0, 28), digest)
            message := keccak256(0, 60)
        }
        assembly {
            let mPtr := mload(0x40)
            let byteLength := mload(signature)

            // store the signature digest
            mstore(mPtr, message)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := shr(248, mload(add(signature, 0x60))) // bitshifting, to resemble padLeft
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // store s
            mstore(add(mPtr, 0x60), s)
            // store r
            mstore(add(mPtr, 0x40), mload(add(signature, 0x20)))
            // store v
            mstore(add(mPtr, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x41
                        eq(byteLength, 0x41),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, mPtr, 0x80, mPtr, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(message, mload(mPtr))
            case 0 {
                recoveredSigner := mload(mPtr)
            }
            mstore(mPtr, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * This 'Unpacked' version expects 'signature' to be a 92-byte array.
     * i.e. the `v` parameter occupies a full 32 bytes of memory, not 1 byte
     * @param hashedMessage - Hashed data being signed over. This function only works if the message has been pre formated to EIP https://eips.ethereum.org/EIPS/eip-191
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateSheildSignatureUnpacked(
        bytes32 hashedMessage,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }
        assembly {
            let mPtr := mload(0x40)
            // There's a little trick we can pull. We expect `signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile
            // load length as a temporary variable
            // N.B. we mutate the signature by re-ordering r, s, and v!
            let byteLength := mload(signature)

            // store the signature digest
            mstore(signature, hashedMessage)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := mload(add(signature, 0x60))
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // move s to v position
            mstore(add(signature, 0x60), s)
            // move r to s position
            mstore(add(signature, 0x40), mload(add(signature, 0x20)))
            // move v to r position
            mstore(add(signature, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x60 (unpacked)
                        eq(byteLength, 0x60),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, signature, 0x80, signature, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(hashedMessage, mload(signature))
            case 0 {
                recoveredSigner := mload(signature)
            }
            mstore(signature, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Extracts the address of the signer with ECDSA. Performs checks on `s` and `v` to
     * to prevent signature malleability based attacks
     * This 'Unpacked' version expects 'signature' to be a 92-byte array.
     * i.e. the `v` parameter occupies a full 32 bytes of memory, not 1 byte
     * @param digest - Hashed data being signed over.
     * @param signature - ECDSA signature over the secp256k1 elliptic curve.
     * @param signer - Address that signs the signature.
     */
    function validateUnpackedSignature(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal view {
        bool result;
        address recoveredSigner = address(0x0);
        if (signer == address(0x0)) {
            revert SIGNATURE_ADDRESS_IS_ZERO();
        }

        // prepend "\x19Ethereum Signed Message:\n32" to the digest to create the signed message
        bytes32 message;
        assembly {
            mstore(0, '\x19Ethereum Signed Message:\n32')
            mstore(28, digest)
            message := keccak256(0, 60)
        }
        assembly {
            // There's a little trick we can pull. We expect `signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile
            // load length as a temporary variable
            // N.B. we mutate the signature by re-ordering r, s, and v!
            let byteLength := mload(signature)

            // store the signature digest
            mstore(signature, message)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := mload(add(signature, 0x60))
            let s := mload(add(signature, 0x40))

            /**
             * Original memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     r
             * signature + 0x40 : signature + 0x60     s
             * signature + 0x60 : signature + 0x80     v
             * Desired memory map for input to precompile
             *
             * signature : signature + 0x20            message
             * signature + 0x20 : signature + 0x40     v
             * signature + 0x40 : signature + 0x60     r
             * signature + 0x60 : signature + 0x80     s
             */

            // move s to v position
            mstore(add(signature, 0x60), s)
            // move r to s position
            mstore(add(signature, 0x40), mload(add(signature, 0x20)))
            // move v to r position
            mstore(add(signature, 0x20), v)
            result := and(
                and(
                    // validate s is in lower half order
                    lt(s, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1),
                    and(
                        // validate signature length == 0x60 (unpacked)
                        eq(byteLength, 0x60),
                        // validate v == 27 or v == 28
                        or(eq(v, 27), eq(v, 28))
                    )
                ),
                // validate call to ecrecover precompile succeeds
                staticcall(gas(), 0x01, signature, 0x80, signature, 0x20)
            )

            // save the recoveredSigner only if the first word in signature is not `message` anymore
            switch eq(message, mload(signature))
            case 0 {
                recoveredSigner := mload(signature)
            }
            mstore(signature, byteLength) // and put the byte length back where it belongs

            // validate that recoveredSigner is not address(0x00)
            result := and(result, not(iszero(recoveredSigner)))
        }
        if (!result) {
            revert SIGNATURE_RECOVERY_FAILED();
        }
        if (recoveredSigner != signer) {
            revert INVALID_SIGNATURE();
        }
    }

    /**
     * Convert a bytes32 into an ASCII encoded hex string
     * @param input bytes32 variable
     * @return result hex-encoded string
     */
    function toHexString(bytes32 input) public pure returns (string memory result) {
        if (uint256(input) == 0x00) {
            assembly {
                result := mload(0x40)
                mstore(result, 0x40)
                mstore(add(result, 0x20), 0x3030303030303030303030303030303030303030303030303030303030303030)
                mstore(add(result, 0x40), 0x3030303030303030303030303030303030303030303030303030303030303030)
                mstore(0x40, add(result, 0x60))
            }
            return result;
        }
        assembly {
            result := mload(0x40)
            let table := add(result, 0x60)

            // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
            // Store lookup table that maps an integer from 0 to ff into a 2-byte ASCII equivalent
            mstore(add(table, 0x1e), 0x3030303130323033303430353036303730383039306130623063306430653066)
            mstore(add(table, 0x3e), 0x3130313131323133313431353136313731383139316131623163316431653166)
            mstore(add(table, 0x5e), 0x3230323132323233323432353236323732383239326132623263326432653266)
            mstore(add(table, 0x7e), 0x3330333133323333333433353336333733383339336133623363336433653366)
            mstore(add(table, 0x9e), 0x3430343134323433343434353436343734383439346134623463346434653466)
            mstore(add(table, 0xbe), 0x3530353135323533353435353536353735383539356135623563356435653566)
            mstore(add(table, 0xde), 0x3630363136323633363436353636363736383639366136623663366436653666)
            mstore(add(table, 0xfe), 0x3730373137323733373437353736373737383739376137623763376437653766)
            mstore(add(table, 0x11e), 0x3830383138323833383438353836383738383839386138623863386438653866)
            mstore(add(table, 0x13e), 0x3930393139323933393439353936393739383939396139623963396439653966)
            mstore(add(table, 0x15e), 0x6130613161326133613461356136613761386139616161626163616461656166)
            mstore(add(table, 0x17e), 0x6230623162326233623462356236623762386239626162626263626462656266)
            mstore(add(table, 0x19e), 0x6330633163326333633463356336633763386339636163626363636463656366)
            mstore(add(table, 0x1be), 0x6430643164326433643464356436643764386439646164626463646464656466)
            mstore(add(table, 0x1de), 0x6530653165326533653465356536653765386539656165626563656465656566)
            mstore(add(table, 0x1fe), 0x6630663166326633663466356636663766386639666166626663666466656666)
            /**
             * Convert `input` into ASCII.
             *
             * Slice 2 base-10  digits off of the input, use to index the ASCII lookup table.
             *
             * We start from the least significant digits, write results into mem backwards,
             * this prevents us from overwriting memory despite the fact that each mload
             * only contains 2 byteso f useful data.
             **/

            let base := input
            function slice(v, tableptr) {
                mstore(0x1e, mload(add(tableptr, shl(1, and(v, 0xff)))))
                mstore(0x1c, mload(add(tableptr, shl(1, and(shr(8, v), 0xff)))))
                mstore(0x1a, mload(add(tableptr, shl(1, and(shr(16, v), 0xff)))))
                mstore(0x18, mload(add(tableptr, shl(1, and(shr(24, v), 0xff)))))
                mstore(0x16, mload(add(tableptr, shl(1, and(shr(32, v), 0xff)))))
                mstore(0x14, mload(add(tableptr, shl(1, and(shr(40, v), 0xff)))))
                mstore(0x12, mload(add(tableptr, shl(1, and(shr(48, v), 0xff)))))
                mstore(0x10, mload(add(tableptr, shl(1, and(shr(56, v), 0xff)))))
                mstore(0x0e, mload(add(tableptr, shl(1, and(shr(64, v), 0xff)))))
                mstore(0x0c, mload(add(tableptr, shl(1, and(shr(72, v), 0xff)))))
                mstore(0x0a, mload(add(tableptr, shl(1, and(shr(80, v), 0xff)))))
                mstore(0x08, mload(add(tableptr, shl(1, and(shr(88, v), 0xff)))))
                mstore(0x06, mload(add(tableptr, shl(1, and(shr(96, v), 0xff)))))
                mstore(0x04, mload(add(tableptr, shl(1, and(shr(104, v), 0xff)))))
                mstore(0x02, mload(add(tableptr, shl(1, and(shr(112, v), 0xff)))))
                mstore(0x00, mload(add(tableptr, shl(1, and(shr(120, v), 0xff)))))
            }

            mstore(result, 0x40)
            slice(base, table)
            mstore(add(result, 0x40), mload(0x1e))
            base := shr(128, base)
            slice(base, table)
            mstore(add(result, 0x20), mload(0x1e))
            mstore(0x40, add(result, 0x60))
        }
    }

    function getSignedMessageForTxId(bytes32 txId) internal view returns (bytes32 hashedMessage) {
        // we know this string length is 64 bytes
        string memory txIdHexString = toHexString(txId);

        assembly {
            let mPtr := mload(0x40)
            mstore(add(mPtr, 32), '\x19Ethereum Signed Message:\n210')
            mstore(add(mPtr, 61), 'Signing this message will allow ')
            mstore(add(mPtr, 93), 'your pending funds to be spent i')
            mstore(add(mPtr, 125), 'n Aztec transaction:\n\n0x')
            mstore(add(mPtr, 149), mload(add(txIdHexString, 0x20)))
            mstore(add(mPtr, 181), mload(add(txIdHexString, 0x40)))
            mstore(add(mPtr, 213), '\n\nIMPORTANT: Only sign the messa')
            mstore(add(mPtr, 245), 'ge if you trust the client')
            hashedMessage := keccak256(add(mPtr, 32), 239)
        }
    }
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec

pragma solidity >=0.6.0 <0.8.11;
pragma experimental ABIEncoderV2;

/**
 * @title Bn254Crypto library used for the fr, g1 and g2 point types
 * @dev Used to manipulate fr, g1, g2 types, perform modular arithmetic on them and call
 * the precompiles add, scalar mul and pairing
 *
 * Notes on optimisations
 * 1) Perform addmod, mulmod etc. in assembly - removes the check that Solidity performs to confirm that
 * the supplied modulus is not 0. This is safe as the modulus's used (r_mod, q_mod) are hard coded
 * inside the contract and not supplied by the user
 */
library Types {
    uint256 constant PROGRAM_WIDTH = 4;
    uint256 constant NUM_NU_CHALLENGES = 11;

    uint256 constant coset_generator0 = 0x0000000000000000000000000000000000000000000000000000000000000005;
    uint256 constant coset_generator1 = 0x0000000000000000000000000000000000000000000000000000000000000006;
    uint256 constant coset_generator2 = 0x0000000000000000000000000000000000000000000000000000000000000007;

    // TODO: add external_coset_generator() method to compute this
    uint256 constant coset_generator7 = 0x000000000000000000000000000000000000000000000000000000000000000c;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fq2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    // N>B. Do not re-order these fields! They must appear in the same order as they
    // appear in the proof data
    struct Proof {
        G1Point W1;
        G1Point W2;
        G1Point W3;
        G1Point W4;
        G1Point Z;
        G1Point T1;
        G1Point T2;
        G1Point T3;
        G1Point T4;
        uint256 w1;
        uint256 w2;
        uint256 w3;
        uint256 w4;
        uint256 sigma1;
        uint256 sigma2;
        uint256 sigma3;
        uint256 q_arith;
        uint256 q_ecc;
        uint256 q_c;
       // uint256 linearization_polynomial;
        uint256 grand_product_at_z_omega;
        uint256 w1_omega;
        uint256 w2_omega;
        uint256 w3_omega;
        uint256 w4_omega;
        G1Point PI_Z;
        G1Point PI_Z_OMEGA;
        G1Point recursive_P1;
        G1Point recursive_P2;
    //    uint256 quotient_polynomial_eval;
        uint256 r_0;
    }

    struct ChallengeTranscript {
        uint256 alpha_base;
        uint256 alpha;
        uint256 zeta;
        uint256 beta;
        uint256 gamma;
        uint256 u;
        uint256 v0;
        uint256 v1;
        uint256 v2;
        uint256 v3;
        uint256 v4;
        uint256 v5;
        uint256 v6;
        uint256 v7;
        uint256 v8;
        uint256 v9;
        uint256 v10;
    }

    struct VerificationKey {
        uint256 circuit_size;
        uint256 num_inputs;
        uint256 work_root;
        uint256 domain_inverse;
        uint256 work_root_inverse;
        G1Point Q1;
        G1Point Q2;
        G1Point Q3;
        G1Point Q4;
        G1Point Q5;
        G1Point QM;
        G1Point QC;
        G1Point QARITH;
        G1Point QECC;
        G1Point QRANGE;
        G1Point QLOGIC;
        G1Point SIGMA1;
        G1Point SIGMA2;
        G1Point SIGMA3;
        G1Point SIGMA4;
        bool contains_recursive_proof;
        uint256 recursive_proof_indices;
        G2Point g2_x;
        // zeta challenge raised to the power of the circuit size.
        // Not actually part of the verification key, but we put it here to prevent stack depth errors
        uint256 zeta_pow_n;
        // necessary fot the simplified plonk
        uint256 zero_polynomial_eval;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.6.0 <0.8.11;
pragma experimental ABIEncoderV2;

import {Types} from './Types.sol';

/**
 * @title Bn254 elliptic curve crypto
 * @dev Provides some basic methods to compute bilinear pairings, construct group elements and misc numerical methods
 */
library Bn254Crypto {
    uint256 constant p_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Perform a modular exponentiation. This method is ideal for small exponents (~64 bits or less), as
    // it is cheaper than using the pow precompile
    function pow_small(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 input = base;
        uint256 count = 1;

        assembly {
            let endpoint := add(exponent, 0x01)
            for {

            } lt(count, endpoint) {
                count := add(count, count)
            } {
                if and(exponent, count) {
                    result := mulmod(result, input, modulus)
                }
                input := mulmod(input, input, modulus)
            }
        }

        return result;
    }

    function invert(uint256 fr) internal view returns (uint256) {
        uint256 output;
        bool success;
        uint256 p = r_mod;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), fr)
            mstore(add(mPtr, 0x80), sub(p, 2))
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            output := mload(0x00)
        }
        require(success, 'pow precompile call failed!');
        return output;
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (Types.G1Point memory) {
        uint256 xValue;
        uint256 yValue;
        assembly {
            xValue := mod(x, r_mod)
            yValue := mod(y, r_mod)
        }
        return Types.G1Point(xValue, yValue);
    }

    function new_g2(
        uint256 x0,
        uint256 x1,
        uint256 y0,
        uint256 y1
    ) internal pure returns (Types.G2Point memory) {
        return Types.G2Point(x0, x1, y0, y1);
    }

    function P1() internal pure returns (Types.G1Point memory) {
        return Types.G1Point(1, 2);
    }

    function P2() internal pure returns (Types.G2Point memory) {
        return
            Types.G2Point({
                x0: 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                x1: 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
                y0: 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                y1: 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            });
    }

    /// Evaluate the following pairing product:
    /// e(a1, a2).e(-b1, b2) == 1
    function pairingProd2(
        Types.G1Point memory a1,
        Types.G2Point memory a2,
        Types.G1Point memory b1,
        Types.G2Point memory b2
    ) internal view returns (bool) {
        validateG1Point(a1);
        validateG1Point(b1);
        bool success;
        uint256 out;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(a1))
            mstore(add(mPtr, 0x20), mload(add(a1, 0x20)))
            mstore(add(mPtr, 0x40), mload(a2))
            mstore(add(mPtr, 0x60), mload(add(a2, 0x20)))
            mstore(add(mPtr, 0x80), mload(add(a2, 0x40)))
            mstore(add(mPtr, 0xa0), mload(add(a2, 0x60)))

            mstore(add(mPtr, 0xc0), mload(b1))
            mstore(add(mPtr, 0xe0), mload(add(b1, 0x20)))
            mstore(add(mPtr, 0x100), mload(b2))
            mstore(add(mPtr, 0x120), mload(add(b2, 0x20)))
            mstore(add(mPtr, 0x140), mload(add(b2, 0x40)))
            mstore(add(mPtr, 0x160), mload(add(b2, 0x60)))
            success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
            out := mload(0x00)
        }
        require(success, 'Pairing check failed!');
        return (out != 0);
    }

    /**
     * validate the following:
     *   x != 0
     *   y != 0
     *   x < p
     *   y < p
     *   y^2 = x^3 + 3 mod p
     */
    function validateG1Point(Types.G1Point memory point) internal pure {
        bool is_well_formed;
        uint256 p = p_mod;
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))

            is_well_formed := and(
                and(and(lt(x, p), lt(y, p)), not(or(iszero(x), iszero(y)))),
                eq(mulmod(y, y, p), addmod(mulmod(x, mulmod(x, x, p), p), 3, p))
            )
        }
        require(is_well_formed, 'Bn254: G1 point not on curve, or is malformed');
    }
}