// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { DataLayrDisclosureLogic } from "../libraries/eigenda/DataLayrDisclosureLogic.sol";
import { IDataLayrServiceManager } from "../libraries/eigenda/interfaces/IDataLayrServiceManager.sol";
import { BN254 } from "../libraries/eigenda/BN254.sol";
import { DataStoreUtils } from "../libraries/eigenda/DataStoreUtils.sol";
import { Parser } from "../libraries/eigenda/Parse.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract BVM_EigenDataLayrChain is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, Parser {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    enum RollupStoreStatus {
        UNCOMMITTED,
        COMMITTED,
        REVERTED
    }

    struct DisclosureProofs {
        bytes header;
        uint32 firstChunkNumber;
        bytes[] polys;
        DataLayrDisclosureLogic.MultiRevealProof[] multiRevealProofs;
        BN254.G2Point polyEquivalenceProof;
    }

    address public sequencer;
    address public dataManageAddress;
    uint256 public BLOCK_STALE_MEASURE;
    uint256 public l2StoredBlockNumber;
    uint256 public l2ConfirmedBlockNumber;
    uint256 public fraudProofPeriod;
    uint256 public rollupBatchIndex;

    bytes public constant FRAUD_STRING = '--This is a bad string. Nobody says this string.--';
    uint256 internal constant DATA_STORE_INITIALIZED_BUT_NOT_CONFIRMED = type(uint256).max;

    struct RollupStore {
        uint32 originDataStoreId;
        uint32 dataStoreId;
        uint32 confirmAt;
        RollupStoreStatus status;
    }

    struct BatchRollupBlock {
        uint256 startL2BlockNumber;
        uint256 endBL2BlockNumber;
        bool    isReRollup;
    }

    mapping(uint256 => RollupStore) public rollupBatchIndexRollupStores;
    mapping(uint32 => BatchRollupBlock) public dataStoreIdToL2RollUpBlock;
    mapping(uint32 => uint256) public dataStoreIdToRollupStoreNumber;
    mapping(address => bool) private fraudProofWhitelist;

    address public reSubmitterAddress;
    uint256 public reRollupIndex;
    mapping(uint256 => uint256) public reRollupBatchIndex;

    event RollupStoreInitialized(uint32 dataStoreId, uint256 stratL2BlockNumber, uint256 endL2BlockNumber);
    event RollupStoreConfirmed(uint256 rollupBatchIndex, uint32 dataStoreId, uint256 stratL2BlockNumber, uint256 endL2BlockNumber);
    event RollupStoreReverted(uint256 rollupBatchIndex, uint32 dataStoreId, uint256 stratL2BlockNumber, uint256 endL2BlockNumber);
    event ReRollupBatchData(uint256 reRollupIndex, uint256 rollupBatchIndex, uint256 stratL2BlockNumber, uint256 endL2BlockNumber);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _sequencer, address _dataManageAddress, address _reSubmitterAddress, uint256 _block_stale_measure, uint256 _fraudProofPeriod, uint256 _l2SubmittedBlockNumber) public initializer {
        __Ownable_init();
        sequencer = _sequencer;
        dataManageAddress = _dataManageAddress;
        reSubmitterAddress = _reSubmitterAddress;
        BLOCK_STALE_MEASURE = _block_stale_measure;
        fraudProofPeriod = _fraudProofPeriod;
        l2StoredBlockNumber = _l2SubmittedBlockNumber;
        l2ConfirmedBlockNumber = _l2SubmittedBlockNumber;
    }

    modifier onlySequencer() {
        require(msg.sender == sequencer, "Only the sequencer can do this action");
        _;
    }

    /**
     * @notice Returns the block number of the latest stored L2.
     * @return Latest stored L2 block number.
     */
    function getL2StoredBlockNumber() public view returns (uint256) {
        return l2StoredBlockNumber;
    }

    /**
     * @notice Returns the block number of the latest stored L2.
     * @return Latest stored L2 block number.
     */
    function getL2ConfirmedBlockNumber() public view returns (uint256) {
        return l2ConfirmedBlockNumber;
    }

    /**
     * @notice Returns the rollup store by l2 block number
     * @return RollupStore.
     */
    function getRollupStoreByRollupBatchIndex(uint256 _rollupBatchIndex) public view returns (RollupStore memory) {
        return rollupBatchIndexRollupStores[_rollupBatchIndex];
    }

    /**
    * @notice Returns the l2 block number by store id
     * @return BatchRollupBlock.
     */
    function getL2RollUpBlockByDataStoreId(uint32 _dataStoreId) public view returns (BatchRollupBlock memory) {
        return dataStoreIdToL2RollUpBlock[_dataStoreId];
    }

    /**
    * @notice set fraud proof address
    * @param _address for fraud proof
    */
    function setFraudProofAddress(address _address) external onlySequencer {
        require(_address != address(0), "setFraudProofAddress: address is the zero address");
        fraudProofWhitelist[_address] = true;
    }

    /**
    * @notice unavailable fraud proof address
    * @param _address for fraud proof
    */
    function unavailableFraudProofAddress(address _address) external onlySequencer {
        require(_address != address(0), "unavailableFraudProofAddress: unavailableFraudProofAddress: address is the zero address");
        fraudProofWhitelist[_address] = false;
    }

    /**
    * @notice remove fraud proof address
    * @param _address for fraud proof
    */
    function removeFraudProofAddress(address _address) external onlySequencer {
        require(_address != address(0), "removeFraudProofAddress: removeFraudProofAddress: address is the zero address");
        delete fraudProofWhitelist[_address];
    }

    /**
    * @notice update fraud proof period
    * @param _fraudProofPeriod fraud proof period
    */
    function updateFraudProofPeriod(uint256 _fraudProofPeriod) external onlySequencer {
        fraudProofPeriod = _fraudProofPeriod;
    }

    /**
    * @notice update dlsm address
    * @param _dataManageAddress dlsm address
    */
    function updateDataLayrManagerAddress(address _dataManageAddress) external onlySequencer {
        require(_dataManageAddress != address(0), "updateDataLayrManagerAddress: _dataManageAddress is the zero address");
        dataManageAddress = _dataManageAddress;
    }

    /**
    * @notice update l2 latest store block number
    * @param _l2StoredBlockNumber l2 latest block number
    */
    function updateL2StoredBlockNumber(uint256 _l2StoredBlockNumber) external onlySequencer {
        l2StoredBlockNumber = _l2StoredBlockNumber;
    }

    /**
    * @notice update l2 latest confirm block number
    * @param _l2ConfirmedBlockNumber l2 latest block number
    */
    function updateL2ConfirmedBlockNumber(uint256 _l2ConfirmedBlockNumber) external onlySequencer {
        l2ConfirmedBlockNumber = _l2ConfirmedBlockNumber;
    }

    /**
    * @notice update sequencer address
    * @param _sequencer update sequencer address
    */
    function updateSequencerAddress(address _sequencer) external onlyOwner {
        require(_sequencer != address(0), "updateSequencerAddress: _sequencer is the zero address");
        sequencer = _sequencer;
    }

    function updateReSubmitterAddress(address _reSubmitterAddress) external onlySequencer {
        require(_reSubmitterAddress != address(0), "updateReSubmitterAddress: _reSubmitterAddress is the zero address");
        reSubmitterAddress = _reSubmitterAddress;
    }

    /**
    * @notice reset batch rollup batch data
    * @param _rollupBatchIndex update rollup index
    */
    function resetRollupBatchData(uint256 _rollupBatchIndex) external onlySequencer {
        for (uint256 i = _rollupBatchIndex; i < rollupBatchIndex; i++) {
            delete rollupBatchIndexRollupStores[i];
        }
        rollupBatchIndex = _rollupBatchIndex;
        l2StoredBlockNumber = 1;
        l2ConfirmedBlockNumber = 1;
    }

    /**
    * @notice submit re-rollup batch index
    * @param batchIndex need re-rollup batch index
    */
    function submitReRollUpInfo(
        uint256 batchIndex
    ) external {
        require(msg.sender == reSubmitterAddress, "submitReRollUpInfo: Only the re submitter can submit re rollup data");
        RollupStore memory rStore = rollupBatchIndexRollupStores[batchIndex];
        if (rStore.dataStoreId > 0) {
            reRollupBatchIndex[reRollupIndex] = batchIndex;
            emit ReRollupBatchData(
                reRollupIndex++,
                batchIndex,
                dataStoreIdToL2RollUpBlock[rStore.dataStoreId].startL2BlockNumber,
                dataStoreIdToL2RollUpBlock[rStore.dataStoreId].endBL2BlockNumber
            );
        }
    }

    /**
     * @notice Called by the (staked) sequencer to pay for a datastore and post some metadata (in the `header` parameter) about it on chain.
     * Since the sequencer must encode the data before they post the header on chain, they must use a *snapshot* of the number and stakes of DataLayr operators
     * from a previous block number, specified by the `blockNumber` input.
     * @param header of data to be stored
     * @param duration is the duration to store the datastore for
     * @param blockNumber is the previous block number which was used to encode the data for storage
     * @param totalOperatorsIndex is index in the totalOperators array of DataLayr referring to what the total number of operators was at `blockNumber`
     * @dev The specified `blockNumber `must be less than `BLOCK_STALE_MEASURE` blocks in the past.
     */
    function storeData(
        bytes calldata header,
        uint8 duration,
        uint32 blockNumber,
        uint256 startL2Block,
        uint256 endL2Block,
        uint32 totalOperatorsIndex,
        bool   isReRollup
    ) external onlySequencer {
        require(endL2Block > startL2Block, "storeData: endL2Block must more than startL2Block");
        require(block.number - blockNumber < BLOCK_STALE_MEASURE, "storeData: stakes taken from too long ago");
        uint32 dataStoreId = IDataLayrServiceManager(dataManageAddress).taskNumber();
        IDataLayrServiceManager(dataManageAddress).initDataStore(
            msg.sender,
            address(this),
            duration,
            blockNumber,
            totalOperatorsIndex,
            header
        );
        dataStoreIdToL2RollUpBlock[dataStoreId] = BatchRollupBlock({
            startL2BlockNumber: startL2Block,
            endBL2BlockNumber: endL2Block,
            isReRollup: isReRollup
        });
        dataStoreIdToRollupStoreNumber[dataStoreId] = DATA_STORE_INITIALIZED_BUT_NOT_CONFIRMED;
        if (!isReRollup) {
            l2StoredBlockNumber = endL2Block;
        }
        emit RollupStoreInitialized(dataStoreId, startL2Block, endL2Block);
    }

    /**
     * @notice After the `storeData `transaction is included in a block and doesn’t revert, the sequencer will disperse the data to the DataLayr nodes off chain
     * and get their signatures that they have stored the data. Now, the sequencer has to post the signature on chain and get it verified.
     * @param data Input of the header information for a dataStore and signatures for confirming the dataStore -- used as input to the `confirmDataStore` function
     * of the DataLayrServiceManager -- see the DataLayr docs for more info on this.
     * @param searchData Data used to specify the dataStore being confirmed. Must be provided so other contracts can properly look up the dataStore.
     * @dev Only dataStores created through this contract can be confirmed by calling this function.
     */
    function confirmData(
        bytes calldata data,
        IDataLayrServiceManager.DataStoreSearchData memory searchData,
        uint256 startL2Block,
        uint256 endL2Block,
        uint32 originDataStoreId,
        uint256 reConfirmedBatchIndex,
        bool isReRollup
    ) external onlySequencer {
        require(endL2Block > startL2Block, "confirmData: endL2Block must more than startL2Block");
        BatchRollupBlock memory batchRollupBlock = dataStoreIdToL2RollUpBlock[searchData.metadata.globalDataStoreId];
        require(batchRollupBlock.startL2BlockNumber == startL2Block &&
            batchRollupBlock.endBL2BlockNumber == endL2Block &&
            batchRollupBlock.isReRollup == isReRollup,
            "confirmData: Data store either was not initialized by the rollup contract, or is already confirmed"
        );
        require(
            dataStoreIdToRollupStoreNumber[searchData.metadata.globalDataStoreId] == DATA_STORE_INITIALIZED_BUT_NOT_CONFIRMED,
            "confirmData: Data store either was not initialized by the rollup contract, or is already confirmed"
        );
        IDataLayrServiceManager(dataManageAddress).confirmDataStore(data, searchData);
        if (!isReRollup) {
            rollupBatchIndexRollupStores[rollupBatchIndex] = RollupStore({
                originDataStoreId: searchData.metadata.globalDataStoreId,
                dataStoreId: searchData.metadata.globalDataStoreId,
                confirmAt: uint32(block.timestamp + fraudProofPeriod),
                status: RollupStoreStatus.COMMITTED
            });
            l2ConfirmedBlockNumber = endL2Block;
            dataStoreIdToRollupStoreNumber[searchData.metadata.globalDataStoreId] = rollupBatchIndex;
            emit RollupStoreConfirmed(uint32(rollupBatchIndex++), searchData.metadata.globalDataStoreId, startL2Block, endL2Block);
        } else {
            rollupBatchIndexRollupStores[reConfirmedBatchIndex] = RollupStore({
                originDataStoreId: originDataStoreId,
                dataStoreId: searchData.metadata.globalDataStoreId,
                confirmAt: uint32(block.timestamp + fraudProofPeriod),
                status: RollupStoreStatus.COMMITTED
            });
            dataStoreIdToRollupStoreNumber[searchData.metadata.globalDataStoreId] = reConfirmedBatchIndex;
            emit RollupStoreConfirmed(reConfirmedBatchIndex, searchData.metadata.globalDataStoreId, startL2Block, endL2Block);
        }
    }

    /**
  * @notice Called by a challenger (this could be anyone -- "challenger" is not a permissioned role) to prove that fraud has occurred.
     * First, a subset of data included in a dataStore that was initiated by the sequencer is proven, and then the presence of fraud in the data is checked.
     * For the sake of this example, "fraud occurring" means that the sequencer included the forbidden `FRAUD_STRING` in a dataStore that they initiated.
     * In pratical use, "fraud occurring" might mean including data that specifies an invalid transaction or invalid state transition.
     * @param fraudulentStoreNumber The rollup l2Block to prove fraud on
     * @param startIndex The index to begin reading the proven data from
     * @param searchData Data used to specify the dataStore being fraud-proven. Must be provided so other contracts can properly look up the dataStore.
     * @param disclosureProofs Non-interactive polynomial proofs that prove that the specific data of interest was part of the dataStore in question.
     * @dev This function is only callable if:
     * -the sequencer is staked,
     * -the dataStore in question has been confirmed, and
     * -the fraudproof period for the dataStore has not yet passed.
     */
    function proveFraud(
        uint256 fraudulentStoreNumber,
        uint256 startIndex,
        IDataLayrServiceManager.DataStoreSearchData memory searchData,
        DisclosureProofs calldata disclosureProofs
    ) external {
        require(fraudProofWhitelist[msg.sender] == true, "proveFraud: Only fraud proof white list can challenge data");
        RollupStore memory rollupStore = rollupBatchIndexRollupStores[fraudulentStoreNumber];
        require(rollupStore.status == RollupStoreStatus.COMMITTED && rollupStore.confirmAt > block.timestamp, "RollupStore must be committed and unconfirmed");
        require(
            IDataLayrServiceManager(dataManageAddress).getDataStoreHashesForDurationAtTimestamp(
                searchData.duration,
                searchData.timestamp,
                searchData.index
            ) == DataStoreUtils.computeDataStoreHash(searchData.metadata),
            "proveFraud: metadata preimage is incorrect"
        );
        require(searchData.metadata.globalDataStoreId == rollupStore.dataStoreId, "seachData's datastore id is not consistent with given rollup store");
        require(searchData.metadata.headerHash == keccak256(disclosureProofs.header), "disclosure proofs headerhash preimage is incorrect");
        require(DataLayrDisclosureLogic.batchNonInteractivePolynomialProofs(
            disclosureProofs.header,
            disclosureProofs.firstChunkNumber,
            disclosureProofs.polys,
            disclosureProofs.multiRevealProofs,
            disclosureProofs.polyEquivalenceProof
        ), "disclosure proofs are invalid");
        uint32 numSys = DataLayrDisclosureLogic.getNumSysFromHeader(disclosureProofs.header);
        require(disclosureProofs.firstChunkNumber + disclosureProofs.polys.length <= numSys, "Can only prove data from the systematic chunks");
        bytes memory provenString = parse(disclosureProofs.polys, startIndex, FRAUD_STRING.length);
        require(provenString.length == FRAUD_STRING.length, "Parsing error, proven string is different length than fraud string");
        require(keccak256(provenString) == keccak256(FRAUD_STRING), "proven string != fraud string");
        rollupBatchIndexRollupStores[fraudulentStoreNumber].status = RollupStoreStatus.REVERTED;
        emit RollupStoreReverted(
            fraudulentStoreNumber,
            searchData.metadata.globalDataStoreId,
            dataStoreIdToL2RollUpBlock[searchData.metadata.globalDataStoreId].startL2BlockNumber,
            dataStoreIdToL2RollUpBlock[searchData.metadata.globalDataStoreId].endBL2BlockNumber
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./interfaces/IDataLayrServiceManager.sol";

/**
 * @title Library of functions shared across DataLayr.
 * @author Layr Labs, Inc.
 */
library DataStoreUtils {
    uint16 public constant BIP_MULTIPLIER = 10000;

    uint256 public constant BYTES_PER_COEFFICIENT = 31;
    uint256 public constant BIT_SHIFT_degree = 224;
    uint256 public constant BIT_SHIFT_numSys = 224;
    uint256 public constant HEADER_OFFSET_degree = 64;
    uint256 public constant HEADER_OFFSET_numSys = 68;


    function getTotalBytes(bytes calldata header, uint32 totalChunks) internal pure returns(uint256) {
        uint256 numCoefficients;
        assembly {
            //numCoefficients = totalChunks * (degree + 1)
            //NOTE: degree + 1 is the number of coefficients
            numCoefficients := mul(totalChunks, add(shr(BIT_SHIFT_degree, calldataload(add(header.offset, HEADER_OFFSET_degree))), 1))
        }
        return numCoefficients * BYTES_PER_COEFFICIENT;
    }
    /// @param header of the datastore that the coding ratio is being retrieved for
    /// @param totalChunks the total number of chunks expected in this datastore
    /// @return codingRatio of the datastore in basis points
    function getCodingRatio(bytes calldata header, uint32 totalChunks) internal pure returns(uint16) {
        uint32 codingRatio;
        assembly {
            //codingRatio = numSys
            codingRatio := shr(BIT_SHIFT_numSys, calldataload(add(header.offset, HEADER_OFFSET_numSys)))
            //codingRatio = numSys * BIP_MULTIPLIER / totalChunks
            codingRatio := div(mul(codingRatio, BIP_MULTIPLIER), totalChunks)
        }
        return uint16(codingRatio);
    }

    function getDegree(bytes calldata header) internal pure returns (uint32) {
        uint32 degree;
        assembly {
            degree := shr(BIT_SHIFT_degree, calldataload(add(header.offset, HEADER_OFFSET_degree)))
        }
        return degree;
    }

    /// @notice Finds the `signatoryRecordHash`, used for fraudproofs.
    function computeSignatoryRecordHash(
        uint32 globalDataStoreId,
        bytes32[] memory nonSignerPubkeyHashes,
        uint256 signedStakeFirstQuorum,
        uint256 signedStakeSecondQuorum
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(globalDataStoreId, nonSignerPubkeyHashes, signedStakeFirstQuorum, signedStakeSecondQuorum)
        );
    }

    /// @notice Computes the hash of a single DataStore's metadata.
    function computeDataStoreHash(IDataLayrServiceManager.DataStoreMetadata memory metadata)
        internal
        pure
        returns (bytes32)
    {
        bytes32 dsHash = keccak256(
            abi.encodePacked(
                metadata.headerHash,
                metadata.durationDataStoreId,
                metadata.globalDataStoreId,
                metadata.referenceBlockNumber,
                metadata.blockNumber,
                metadata.fee,
                metadata.confirmer,
                metadata.signatoryRecordHash
            )
        );
        return dsHash;
    }

    /// @notice uses `abi.encodePacked` to encode a DataStore's metadata into a compressed format
    function packDataStoreMetadata(IDataLayrServiceManager.DataStoreMetadata memory metadata)
        internal
        pure
        returns (bytes memory)
    {
        return (
            abi.encodePacked(
                metadata.headerHash,
                metadata.durationDataStoreId,
                metadata.globalDataStoreId,
                metadata.referenceBlockNumber,
                metadata.blockNumber,
                metadata.fee,
                metadata.confirmer,
                metadata.signatoryRecordHash
            )
        );
    }

    /// @notice uses `abi.encodePacked` to encode a DataStore's searchData into a compressed format
    function packDataStoreSearchData(IDataLayrServiceManager.DataStoreSearchData memory searchData)
        internal
        pure
        returns (bytes memory)
    {
        return (
            abi.encodePacked(
                packDataStoreMetadata(searchData.metadata), searchData.duration, searchData.timestamp, searchData.index
            )
        );
    }

    // CONSTANTS -- commented out lines are due to inline assembly supporting *only* 'direct number constants' (for now, at least)
    // OBJECT BIT LENGTHS
    uint256 internal constant BIT_LENGTH_headerHash = 256;
    uint256 internal constant BIT_LENGTH_durationDataStoreId = 32;
    uint256 internal constant BIT_LENGTH_globalDataStoreId = 32;
    uint256 internal constant BIT_LENGTH_referenceBlockNumber = 32;
    uint256 internal constant BIT_LENGTH_blockNumber = 32;
    uint256 internal constant BIT_LENGTH_fee = 96;
    uint256 internal constant BIT_LENGTH_confirmer = 160;
    uint256 internal constant BIT_LENGTH_signatoryRecordHash = 256;
    uint256 internal constant BIT_LENGTH_duration = 8;
    uint256 internal constant BIT_LENGTH_timestamp = 256;
    uint256 internal constant BIT_LENGTH_index = 32;

    // OBJECT BIT SHIFTS FOR READING FROM CALLDATA -- don't bother with using 'shr' if any of these is 0
    // uint256 internal constant BIT_SHIFT_headerHash = 256 - BIT_LENGTH_headerHash;
    // uint256 internal constant BIT_SHIFT_durationDataStoreId = 256 - BIT_LENGTH_durationDataStoreId;
    // uint256 internal constant BIT_SHIFT_globalDataStoreId = 256 - BIT_LENGTH_globalDataStoreId;
    // uint256 internal constant BIT_SHIFT_referenceBlockNumber = 256 - BIT_LENGTH_referenceBlockNumber;
    // uint256 internal constant BIT_SHIFT_blockNumber = 256 - BIT_LENGTH_blockNumber;
    // uint256 internal constant BIT_SHIFT_fee = 256 - BIT_LENGTH_fee;
    // uint256 internal constant BIT_SHIFT_confirmer = 256 - BIT_LENGTH_confirmer;
    // uint256 internal constant BIT_SHIFT_signatoryRecordHash = 256 - BIT_LENGTH_signatoryRecordHash;
    // uint256 internal constant BIT_SHIFT_duration = 256 - BIT_LENGTH_duration;
    // uint256 internal constant BIT_SHIFT_timestamp = 256 - BIT_LENGTH_timestamp;
    // uint256 internal constant BIT_SHIFT_index = 256 - BIT_LENGTH_index;
    uint256 internal constant BIT_SHIFT_headerHash = 0;
    uint256 internal constant BIT_SHIFT_durationDataStoreId = 224;
    uint256 internal constant BIT_SHIFT_globalDataStoreId = 224;
    uint256 internal constant BIT_SHIFT_referenceBlockNumber = 224;
    uint256 internal constant BIT_SHIFT_blockNumber = 224;
    uint256 internal constant BIT_SHIFT_fee = 160;
    uint256 internal constant BIT_SHIFT_confirmer = 96;
    uint256 internal constant BIT_SHIFT_signatoryRecordHash = 0;
    uint256 internal constant BIT_SHIFT_duration = 248;
    uint256 internal constant BIT_SHIFT_timestamp = 0;
    uint256 internal constant BIT_SHIFT_index = 224;

    // CALLDATA OFFSETS IN BYTES -- adding 7 and dividing by 8 here is for rounding *up* the bit amounts to bytes amounts
    // uint256 internal constant CALLDATA_OFFSET_headerHash = 0;
    // uint256 internal constant CALLDATA_OFFSET_durationDataStoreId = ((BIT_LENGTH_headerHash + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_globalDataStoreId = CALLDATA_OFFSET_durationDataStoreId + ((BIT_LENGTH_durationDataStoreId + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_referenceBlockNumber = CALLDATA_OFFSET_globalDataStoreId + ((BIT_LENGTH_globalDataStoreId + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_blockNumber = CALLDATA_OFFSET_referenceBlockNumber + ((BIT_LENGTH_referenceBlockNumber + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_fee = CALLDATA_OFFSET_blockNumber + ((BIT_LENGTH_blockNumber + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_confirmer = CALLDATA_OFFSET_fee + ((BIT_LENGTH_fee + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_signatoryRecordHash = CALLDATA_OFFSET_confirmer + ((BIT_LENGTH_confirmer + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_duration = CALLDATA_OFFSET_signatoryRecordHash + ((BIT_LENGTH_signatoryRecordHash + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_timestamp = CALLDATA_OFFSET_duration + ((BIT_LENGTH_duration + 7) / 8);
    // uint256 internal constant CALLDATA_OFFSET_index = CALLDATA_OFFSET_timestamp + ((BIT_LENGTH_timestamp + 7) / 8);
    uint256 internal constant CALLDATA_OFFSET_headerHash = 0;
    uint256 internal constant CALLDATA_OFFSET_durationDataStoreId = 32;
    uint256 internal constant CALLDATA_OFFSET_globalDataStoreId = 36;
    uint256 internal constant CALLDATA_OFFSET_referenceBlockNumber = 40;
    uint256 internal constant CALLDATA_OFFSET_blockNumber = 44;
    uint256 internal constant CALLDATA_OFFSET_fee = 48;
    uint256 internal constant CALLDATA_OFFSET_confirmer = 60;
    uint256 internal constant CALLDATA_OFFSET_signatoryRecordHash = 80;
    uint256 internal constant CALLDATA_OFFSET_duration = 112;
    uint256 internal constant CALLDATA_OFFSET_timestamp = 113;
    uint256 internal constant CALLDATA_OFFSET_index = 145;

    // MEMORY OFFSETS IN BYTES
    uint256 internal constant MEMORY_OFFSET_headerHash = 0;
    uint256 internal constant MEMORY_OFFSET_durationDataStoreId = 32;
    uint256 internal constant MEMORY_OFFSET_globalDataStoreId = 64;
    uint256 internal constant MEMORY_OFFSET_referenceBlockNumber = 96;
    uint256 internal constant MEMORY_OFFSET_blockNumber = 128;
    uint256 internal constant MEMORY_OFFSET_fee = 160;
    uint256 internal constant MEMORY_OFFSET_confirmer = 192;
    uint256 internal constant MEMORY_OFFSET_signatoryRecordHash = 224;
    /**
    *  Here MEMORY_OFFSET_duration is only 32 despite metadata struct being much longer
    *  than 32 bytes.  I'm unsure why the memory-offsets work this way, but they do. See usage below.
    */
    uint256 internal constant MEMORY_OFFSET_duration = 32;
    uint256 internal constant MEMORY_OFFSET_timestamp = 64;
    uint256 internal constant MEMORY_OFFSET_index = 96;

    /**
     * @notice Unpacks the packed metadata of a DataStore into a metadata struct.
     * @param packedMetadata should be in the same form as the output of `packDataStoreMetadata`
     */
    function unpackDataStoreMetadata(bytes calldata packedMetadata)
        internal
        pure
        returns (IDataLayrServiceManager.DataStoreMetadata memory metadata)
    {
        uint256 pointer;
        assembly {
            // fetch offset of `packedMetadata` input in calldata
            pointer := packedMetadata.offset
            mstore(
                // store in the headerHash memory location in `metadata`
                metadata,
                // read the headerHash from its calldata position in `packedMetadata`
                calldataload(pointer)
            )
            mstore(
                // store in the durationDataStoreId memory location in `metadata`
                add(metadata, MEMORY_OFFSET_durationDataStoreId),
                // read the durationDataStoreId from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_durationDataStoreId, calldataload(add(pointer, CALLDATA_OFFSET_durationDataStoreId)))
            )
            mstore(
                // store in the globalDataStoreId memory location in `metadata`
                add(metadata, MEMORY_OFFSET_globalDataStoreId),
                // read the globalDataStoreId from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_globalDataStoreId, calldataload(add(pointer, CALLDATA_OFFSET_globalDataStoreId)))
            )
            mstore(
                // store in the blockNumber memory location in `metadata`
                add(metadata, MEMORY_OFFSET_referenceBlockNumber),
                // read the blockNumber from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_blockNumber, calldataload(add(pointer, CALLDATA_OFFSET_referenceBlockNumber)))
            )
            mstore(
                // store in the blockNumber memory location in `metadata`
                add(metadata, MEMORY_OFFSET_blockNumber),
                // read the blockNumber from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_blockNumber, calldataload(add(pointer, CALLDATA_OFFSET_blockNumber)))
            )
            mstore(
                // store in the fee memory location in `metadata`
                add(metadata, MEMORY_OFFSET_fee),
                // read the fee from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_fee, calldataload(add(pointer, CALLDATA_OFFSET_fee)))
            )
            mstore(
                // store in the confirmer memory location in `metadata`
                add(metadata, MEMORY_OFFSET_confirmer),
                // read the confirmer from its calldata position in `packedMetadata`
                shr(BIT_SHIFT_confirmer, calldataload(add(pointer, CALLDATA_OFFSET_confirmer)))
            )
            mstore(
                // store in the signatoryRecordHash memory location in `metadata`
                add(metadata, MEMORY_OFFSET_signatoryRecordHash),
                // read the signatoryRecordHash from its calldata position in `packedMetadata`
                calldataload(add(pointer, CALLDATA_OFFSET_signatoryRecordHash))
            )
        }
        return metadata;
    }

    /**
     * @notice Unpacks the packed searchData of a DataStore into a searchData struct.
     * @param packedSearchData should be in the same form as the output of `packDataStoreSearchData`
     */
    function unpackDataStoreSearchData(bytes calldata packedSearchData)
        internal
        pure
        returns (IDataLayrServiceManager.DataStoreSearchData memory searchData)
    {
        searchData.metadata = (unpackDataStoreMetadata(packedSearchData));
        uint256 pointer;
        assembly {
            // fetch offset of `packedSearchData` input in calldata
            pointer := packedSearchData.offset
            mstore(
                // store in the duration memory location of `searchData`
                add(searchData, MEMORY_OFFSET_duration),
                // read the duration from its calldata position in `packedSearchData`
                shr(BIT_SHIFT_duration, calldataload(add(pointer, CALLDATA_OFFSET_duration)))
            )
            mstore(
                // store in the timestamp memory location of `searchData`
                add(searchData, MEMORY_OFFSET_timestamp),
                // read the timestamp from its calldata position in `packedSearchData`
                calldataload(add(pointer, CALLDATA_OFFSET_timestamp))
            )
            mstore(
                // store in the index memory location of `searchData`
                add(searchData, MEMORY_OFFSET_index),
                // read the index from its calldata position in `packedSearchData`
                shr(BIT_SHIFT_index, calldataload(add(pointer, CALLDATA_OFFSET_index)))
            )
        }
        return searchData;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Merkle.sol";
import "./BN254.sol";
import "./interfaces/IDataLayrServiceManager.sol";

library DataLayrDisclosureLogic {
    uint256 constant MODULUS =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct MultiRevealProof {
        BN254.G1Point interpolationPoly;
        BN254.G1Point revealProof;
        BN254.G2Point zeroPoly;
        bytes zeroPolyProof;
    }

    struct DataStoreKZGMetadata {
        BN254.G1Point c;
        uint48 degree;
        uint32 numSys;
        uint32 numPar;
    }

    function getDataCommitmentAndMultirevealDegreeAndSymbolBreakdownFromHeader(
    // bytes calldata header
        bytes calldata header
    ) internal pure returns (DataStoreKZGMetadata memory) {
        // return x, y coordinate of overall data poly commitment
        // then return degree of multireveal polynomial
        BN254.G1Point memory point;
        uint48 degree;
        uint32 numSys;
        uint32 numPar;
        uint256 pointer;

        assembly {
            pointer := header.offset
            mstore(point, calldataload(pointer))
            mstore(add(point, 0x20), calldataload(add(pointer, 32)))
        //TODO: PUT THE LOW DEGREENESS PROOF HERE
            degree := shr(224, calldataload(add(pointer, 64)))

            numSys := shr(224, calldataload(add(pointer, 68)))
            numPar := shr(224, calldataload(add(pointer, 72)))
        }

        return
        DataStoreKZGMetadata({
        c: point,
        degree: degree,
        numSys: numSys,
        numPar: numPar
        });
    }

    function getNumSysFromHeader(
    // bytes calldata header
        bytes calldata header
    ) internal pure returns (uint32) {
        uint32 numSys;

        assembly {
            numSys := shr(224, calldataload(add(header.offset, 68)))
        }

        return numSys;
    }

    function getLeadingCosetIndexFromHighestRootOfUnity(
        uint32 i,
        uint32 numSys,
        uint32 numPar
    ) internal pure returns (uint32) {
        uint32 numNode = numSys + numPar;
        uint32 numSysE = uint32(nextPowerOf2(numSys));
        uint32 ratio = numNode / numSys + (numNode % numSys == 0 ? 0 : 1);
        uint32 numNodeE = uint32(nextPowerOf2(numSysE * ratio));

        if (i < numSys) {
            return
            (reverseBitsLimited(uint32(numNodeE), uint32(i)) * 256) /
            numNodeE;
        } else if (i < numNodeE - (numSysE - numSys)) {
            return
            (reverseBitsLimited(
                uint32(numNodeE),
                uint32((i - numSys) + numSysE)
            ) * 256) / numNodeE;
        } else {
            revert("Cannot create number of frame higher than possible");
        }
    }

    function reverseBitsLimited(uint32 length, uint32 value)
    internal
    pure
    returns (uint32)
    {
        uint32 unusedBitLen = 32 - uint32(log2(length));
        return reverseBits(value) >> unusedBitLen;
    }

    function reverseBits(uint32 value) internal pure returns (uint32) {
        uint256 reversed = 0;
        for (uint i = 0; i < 32; i++) {
            uint256 mask = 1 << i;
            if (value & mask != 0) {
                reversed |= (1 << (31 - i));
            }
        }
        return uint32(reversed);
    }

    //takes the log base 2 of n and returns it
    function log2(uint256 n) internal pure returns (uint256) {
        require(n > 0, "Log must be defined");
        uint256 log = 0;
        while (n >> log != 1) {
            log++;
        }
        return log;
    }

    //finds the next power of 2 greater than n and returns it
    function nextPowerOf2(uint256 n) internal pure returns (uint256) {
        uint256 res = 1;
        while (1 << res < n) {
            res++;
        }
        res = 1 << res;
        return res;
    }

    // gets the merkle root of a tree where all the leaves are the hashes of the zero/vanishing polynomials of the given multireveal
    // degree at different roots of unity. We are assuming a max of 512 datalayr nodes  right now, so, for merkle root for "degree"
    // will be of the tree where the leaves are the hashes of the G2 kzg commitments to the following polynomials:
    // l = degree (for brevity)
    // w^(512*l) = 1
    // (s^l - 1), (s^l - w^l), (s^l - w^2l), (s^l - w^3l), (s^l - w^4l), ...
    // we have precomputed these values and return them directly because it's cheap. currently we
    // tolerate up to degree 2^10, which means up to (31 bytes/point)(1024 points/dln)(256 dln) = 8 MB in a datastore
    function getZeroPolyMerkleRoot(uint256 degree)
    internal
    pure
    returns (bytes32)
    {
        uint256 log = log2(degree);

        if (log == 0) {
            return
            0xe82cea94884b1b895ea0742840a3b19249a723810fd1b04d8564d675b0a416f1;
        } else if (log == 1) {
            return
            0x4843774a80fc8385b31024f5bd18b42e62de439206ab9468d42d826796d41f67;
        } else if (log == 2) {
            return
            0x092d3e5f87f5293e7ab0cc2ca6b0b5e4adb5e0011656544915f7cea34e69e5ab;
        } else if (log == 3) {
            return
            0x494b208540ec8624fbbb3f2c64ffccdaf6253f8f4e50c0d93922d88195b07755;
        } else if (log == 4) {
            return
            0xfdb44b84a82893cfa0e37a97f09ffc4298ad5e62be1bea1d03320ae836213d22;
        } else if (log == 5) {
            return
            0x3f50cb08231d2a76853ba9dbb20dad45a1b75c57cdaff6223bfe069752cff3d4;
        } else if (log == 6) {
            return
            0xbb39eebd8138eefd5802a49d571e65b3e0d4e32277c28fbf5fbca66e7fb04310;
        } else if (log == 7) {
            return
            0xf0a39b513e11fa80cbecbf352f69310eddd5cd03148768e0e9542bd600b133ec;
        } else if (log == 8) {
            return
            0x038cca2238865414efb752cc004fffec9e6069b709f495249cdf36efbd5952f6;
        } else if (log == 9) {
            return
            0x2a26b054ed559dd255d8ac9060ebf6b95b768d87de767f8174ad2f9a4e48dd01;
        } else if (log == 10) {
            return
            0x1fe180d0bc4ff7c69fefa595b3b5f3c284535a280f6fdcf69b20770d1e20e1fc;
        } else if (log == 11) {
            return
            0x60e34ad57c61cd6fdd8177437c30e4a30334e63d7683989570cf27020efc8201;
        } else if (log == 12) {
            return
            0xeda2417e770ddbe88f083acf06b6794dfb76301314a32bd0697440d76f6cd9cc;
        } else if (log == 13) {
            return
            0x8cbe9b8cf92ce70e3bec8e1e72a0f85569017a7e43c3db50e4a5badb8dea7ce8;
        } else {
            revert("Log not in valid range");
        }
    }

    // opens up kzg commitment c(x) at r and makes sure c(r) = s. proof (pi) is in G2 to allow for calculation of Z in G1
    function openPolynomialAtPoint(
        BN254.G1Point memory c,
        BN254.G2Point calldata pi,
        uint256 r,
        uint256 s
    ) internal view returns (bool) {
        //we use and overwrite z as temporary storage
        //g1 = (1, 2)
        BN254.G1Point memory g1Gen = BN254.G1Point({X: 1, Y: 2});
        //calculate -g1*r = -[r]_1
        BN254.G1Point memory z = BN254.scalar_mul(BN254.negate(g1Gen), r);

        //add [x]_1 - [r]_1 = Z and store in first 2 slots of input
        //CRITIC TODO: SWITCH THESE TO [x]_1 of Powers of Tau!
        BN254.G1Point memory firstPowerOfTau = BN254.G1Point({
        X: 15397661830938158195220872607788450164522003659458108417904919983213308643927,
        Y: 4051901473739185471504766068400292374549287637553596337727654132125147894034
        });
        z = BN254.plus(firstPowerOfTau, z);
        //calculate -g1*s = -[s]_1
        BN254.G1Point memory negativeS = BN254.scalar_mul(
            BN254.negate(g1Gen),
            s
        );
        //calculate C-[s]_1
        BN254.G1Point memory cMinusS = BN254.plus(c, negativeS);

        //check e(z, pi)e(C-[s]_1, -g2) = 1
        return BN254.pairing(z, pi, cMinusS, BN254.negGeneratorG2());
    }

    function validateDisclosureResponse(
        DataStoreKZGMetadata memory dskzgMetadata,
        uint32 chunkNumber,
        BN254.G1Point calldata interpolationPoly,
        BN254.G1Point calldata revealProof,
        BN254.G2Point memory zeroPoly,
        bytes calldata zeroPolyProof
    ) internal view returns (bool) {
        // check that [zeroPoly.x0, zeroPoly.x1, zeroPoly.y0, zeroPoly.y1] is actually the "chunkNumber" leaf
        // of the zero polynomial Merkle tree

        {
            //deterministic assignment of "y" here
            // @todo
            require(
                Merkle.verifyInclusionKeccak(
                // Merkle proof
                    zeroPolyProof,
                // Merkle root hash
                    getZeroPolyMerkleRoot(dskzgMetadata.degree),
                // leaf
                    keccak256(
                        abi.encodePacked(
                            zeroPoly.X[1],
                            zeroPoly.X[0],
                            zeroPoly.Y[1],
                            zeroPoly.Y[0]
                        )
                    ),
                // index in the Merkle tree
                    getLeadingCosetIndexFromHighestRootOfUnity(
                        chunkNumber,
                        dskzgMetadata.numSys,
                        dskzgMetadata.numPar
                    )
                ),
                "Incorrect zero poly merkle proof"
            );
        }

        /**
         Doing pairing verification  e(Pi(s), Z_k(s)).e(C - I, -g2) == 1
         */
        //get the commitment to the zero polynomial of multireveal degree

        // calculate [C]_1 - [I]_1
        BN254.G1Point memory cMinusI = BN254.plus(
            dskzgMetadata.c,
            BN254.negate(interpolationPoly)
        );

        //check e(z, pi)e(C-[s]_1, -g2) = 1
        return BN254.pairing(revealProof, zeroPoly, cMinusI, BN254.negGeneratorG2());
    }

    function nonInteractivePolynomialProof(
        bytes calldata header,
        uint32 chunkNumber,
        bytes calldata poly,
        MultiRevealProof calldata multiRevealProof,
        BN254.G2Point calldata polyEquivalenceProof
    ) internal view returns (bool) {
        DataStoreKZGMetadata
        memory dskzgMetadata = getDataCommitmentAndMultirevealDegreeAndSymbolBreakdownFromHeader(
            header
        );

        //verify pairing for the commitment to interpolating polynomial
        require(
            validateDisclosureResponse(
                dskzgMetadata,
                chunkNumber,
                multiRevealProof.interpolationPoly,
                multiRevealProof.revealProof,
                multiRevealProof.zeroPoly,
                multiRevealProof.zeroPolyProof
            ),
            "Reveal failed due to non 1 pairing"
        );

        // TODO: verify that this check is correct!
        // check that degree of polynomial in the header matches the length of the submitted polynomial
        // i.e. make sure submitted polynomial doesn't contain extra points
        require(
            (dskzgMetadata.degree + 1) * 32 == poly.length,
            "Polynomial must have a 256 bit coefficient for each term"
        );

        //Calculating r, the point at which to evaluate the interpolating polynomial
        uint256 r = uint256(
            keccak256(
                abi.encodePacked(
                    keccak256(poly),
                    multiRevealProof.interpolationPoly.X,
                    multiRevealProof.interpolationPoly.Y
                )
            )
        ) % MODULUS;
        uint256 s = linearPolynomialEvaluation(poly, r);
        return
        openPolynomialAtPoint(
            multiRevealProof.interpolationPoly,
            polyEquivalenceProof,
            r,
            s
        );
    }

    function verifyPolyEquivalenceProof(
        bytes calldata poly,
        BN254.G1Point calldata interpolationPoly,
        BN254.G2Point calldata polyEquivalenceProof
    ) internal view returns (bool) {
        //Calculating r, the point at which to evaluate the interpolating polynomial
        uint256 r = uint256(
            keccak256(
                abi.encodePacked(
                    keccak256(poly),
                    interpolationPoly.X,
                    interpolationPoly.Y
                )
            )
        ) % MODULUS;
        uint256 s = linearPolynomialEvaluation(poly, r);
        bool ok = openPolynomialAtPoint(
            interpolationPoly,
            polyEquivalenceProof,
            r,
            s
        );
        return ok;
    }

    function verifyBatchPolyEquivalenceProof(
        bytes[] calldata polys,
        BN254.G1Point[] calldata interpolationPolys,
        BN254.G2Point calldata polyEquivalenceProof
    ) internal view returns (bool) {
        bytes32[] memory rs = new bytes32[](polys.length);
        //Calculating r, the point at which to evaluate the interpolating polynomial
        for (uint i = 0; i < polys.length; i++) {
            rs[i] = keccak256(
                abi.encodePacked(
                    keccak256(polys[i]),
                    interpolationPolys[i].X,
                    interpolationPolys[i].Y
                )
            );
        }
        //this is the point to open each polynomial at
        uint256 r = uint256(keccak256(abi.encodePacked(rs))) % MODULUS;
        //this is the offset we add to each polynomial to prevent collision
        //we use array to help with stack
        uint256[2] memory gammaAndGammaPower;
        gammaAndGammaPower[0] =
        uint256(keccak256(abi.encodePacked(rs, uint256(0)))) %
        MODULUS;
        gammaAndGammaPower[1] = gammaAndGammaPower[0];
        //store I1
        BN254.G1Point memory gammaShiftedCommitmentSum = interpolationPolys[0];
        //store I1(r)
        uint256 gammaShiftedEvaluationSum = linearPolynomialEvaluation(
            polys[0],
            r
        );
        for (uint i = 1; i < interpolationPolys.length; i++) {
            //gammaShiftedCommitmentSum += gamma^i * Ii
            gammaShiftedCommitmentSum = BN254.plus(
                gammaShiftedCommitmentSum,
                BN254.scalar_mul(interpolationPolys[i], gammaAndGammaPower[1])
            );
            //gammaShiftedEvaluationSum += gamma^i * Ii(r)
            uint256 eval = linearPolynomialEvaluation(polys[i], r);
            gammaShiftedEvaluationSum = addmod(
                gammaShiftedEvaluationSum,
                mulmod(gammaAndGammaPower[1], eval, MODULUS),
                MODULUS
            );
            // gammaPower = gamma^(i+1)
            gammaAndGammaPower[1] = mulmod(
                gammaAndGammaPower[0],
                gammaAndGammaPower[1],
                MODULUS
            );
        }

        return
        openPolynomialAtPoint(
            gammaShiftedCommitmentSum,
            polyEquivalenceProof,
            r,
            gammaShiftedEvaluationSum
        );
    }

    function batchNonInteractivePolynomialProofs(
        bytes calldata header,
        uint32 firstChunkNumber,
        bytes[] calldata polys,
        MultiRevealProof[] calldata multiRevealProofs,
        BN254.G2Point calldata polyEquivalenceProof
    ) internal view returns (bool) {
        //randomness from each polynomial
        bytes32[] memory rs = new bytes32[](polys.length);
        DataStoreKZGMetadata
        memory dskzgMetadata = getDataCommitmentAndMultirevealDegreeAndSymbolBreakdownFromHeader(
            header
        );
        uint256 numProofs = multiRevealProofs.length;
        for (uint256 i = 0; i < numProofs; ) {
            //verify pairing for the commitment to interpolating polynomial
            require(
                validateDisclosureResponse(
                    dskzgMetadata,
                    firstChunkNumber + uint32(i),
                    multiRevealProofs[i].interpolationPoly,
                    multiRevealProofs[i].revealProof,
                    multiRevealProofs[i].zeroPoly,
                    multiRevealProofs[i].zeroPolyProof
                ),
                "Reveal failed due to non 1 pairing"
            );

            // TODO: verify that this check is correct!
            // check that degree of polynomial in the header matches the length of the submitted polynomial
            // i.e. make sure submitted polynomial doesn't contain extra points
            require(
                dskzgMetadata.degree * 32 == polys[i].length,
                "Polynomial must have a 256 bit coefficient for each term"
            );

            //Calculating r, the point at which to evaluate the interpolating polynomial
            rs[i] = keccak256(
                abi.encodePacked(
                    keccak256(polys[i]),
                    multiRevealProofs[i].interpolationPoly.X,
                    multiRevealProofs[i].interpolationPoly.Y
                )
            );
        unchecked {
            ++i;
        }
        }
        //this is the point to open each polynomial at
        uint256 r = uint256(keccak256(abi.encodePacked(rs))) % MODULUS;
        //this is the offset we add to each polynomial to prevent collision
        //we use array to help with stack
        uint256[2] memory gammaAndGammaPower;
        gammaAndGammaPower[0] =
        uint256(keccak256(abi.encodePacked(rs, uint256(0)))) %
        MODULUS;
        gammaAndGammaPower[1] = gammaAndGammaPower[0];
        //store I1
        BN254.G1Point memory gammaShiftedCommitmentSum = multiRevealProofs[0]
        .interpolationPoly;
        //store I1(r)
        uint256 gammaShiftedEvaluationSum = linearPolynomialEvaluation(
            polys[0],
            r
        );
        for (uint i = 1; i < multiRevealProofs.length; i++) {
            //gammaShiftedCommitmentSum += gamma^i * Ii
            gammaShiftedCommitmentSum = BN254.plus(
                gammaShiftedCommitmentSum,
                BN254.scalar_mul(
                    multiRevealProofs[i].interpolationPoly,
                    gammaAndGammaPower[1]
                )
            );
            //gammaShiftedEvaluationSum += gamma^i * Ii(r)
            uint256 eval = linearPolynomialEvaluation(polys[i], r);
            gammaShiftedEvaluationSum = gammaShiftedEvaluationSum = addmod(
                gammaShiftedEvaluationSum,
                mulmod(gammaAndGammaPower[1], eval, MODULUS),
                MODULUS
            );
            // gammaPower = gamma^(i+1)
            gammaAndGammaPower[1] = mulmod(
                gammaAndGammaPower[0],
                gammaAndGammaPower[1],
                MODULUS
            );
        }

        return
        openPolynomialAtPoint(
            gammaShiftedCommitmentSum,
            polyEquivalenceProof,
            r,
            gammaShiftedEvaluationSum
        );
    }

    //evaluates the given polynomial "poly" at value "r" and returns the result
    function linearPolynomialEvaluation(bytes calldata poly, uint256 r)
    internal
    pure
    returns (uint256)
    {
        uint256 sum;
        uint256 length = poly.length;
        uint256 rPower = 1;
        for (uint i = 0; i < length; ) {
            uint256 coefficient = uint256(bytes32(poly[i:i + 32]));
            sum = addmod(sum, mulmod(coefficient, rPower, MODULUS), MODULUS);
            rPower = mulmod(rPower, r, MODULUS);
            i += 32;
        }
        return sum;
    }
}

// SPDX-License-Identifier: UNLICENSED AND MIT
// several functions are taken or adapted from https://github.com/HarryR/solcrypto/blob/master/contracts/altbn128.sol (MIT license):
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// The remainder of the code is written by LayrLabs Inc. and UNLICENSED

pragma solidity ^0.8.9;

/**
 * @title Library for operations on the BN254 elliptic curve.
 * @author Layr Labs, Inc.
 * @notice Contains BN254 parameters, common operations (addition, scalar mul, pairing), and BLS signature functionality.
 */
library BN254 {
    // modulus for the underlying field F_p of the elliptic curve
    uint256 internal constant FP_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // modulus for the underlying field F_r of the elliptic curve
    uint256 internal constant FR_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // primitive root of unity
    uint256 internal constant OMEGA = 10359452186428527605436343203440067497552205259388878191021578220384701716497;


    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[1] * i + X[0]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    // generator of group G2
    /// @dev Generator point in F_q2 is of the form: (x0 + ix1, y0 + iy1).
    uint256 internal constant G2x1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 internal constant G2x0 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 internal constant G2y1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 internal constant G2y0 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;
    /// @notice returns the G2 generator
    /// @dev mind the ordering of the 1s and 0s!
    ///      this is because of the (unknown to us) convention used in the bn254 pairing precompile contract
    ///      "Elements a * i + b of F_p^2 are encoded as two elements of F_p, (a, b)."
    ///      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-197.md#encoding
    function generatorG2() internal pure returns (G2Point memory) {
        return G2Point(
            [G2x1, G2x0], [G2y1, G2y0]
        );
    }

    // negation of the generator of group G2
    /// @dev Generator point in F_q2 is of the form: (x0 + ix1, y0 + iy1).
    uint256 internal constant nG2x1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 internal constant nG2x0 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 internal constant nG2y1 =
        17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 internal constant nG2y0 =
        13392588948715843804641432497768002650278120570034223513918757245338268106653;
    function negGeneratorG2() internal pure returns (G2Point memory) {
        return G2Point(
            [nG2x1, nG2x0], [nG2y1, nG2y0]
        );
    }

    // first power of srs in G2
    // TODO: change in production
    uint256 internal constant G2SRSx1 = 7912312892787135728292535536655271843828059318189722219035249994421084560563;
    uint256 internal constant G2SRSx0 = 21039730876973405969844107393779063362038454413254731404052240341412356318284;
    uint256 internal constant G2SRSy1 = 18697407556011630376420900106252341752488547575648825575049647403852275261247;
    uint256 internal constant G2SRSy0 = 7586489485579523767759120334904353546627445333297951253230866312564920951171;
    function G2SRSFirstPower() internal pure returns (G2Point memory) {
        return G2Point(
            [G2SRSx0, G2SRSx1], [G2SRSy0, G2SRSy1]
        );
    }

    bytes32 internal constant powersOfTauMerkleRoot =
        0x22c998e49752bbb1918ba87d6d59dd0e83620a311ba91dd4b2cc84990b31b56f;


    /**
     * @param p Some point in G1.
     * @return The negation of `p`, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, FP_MODULUS - (p.Y % FP_MODULUS));
        }
    }

    /**
     * @return r the sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, r, 0x40)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "ec-add-failed");
    }

    /**
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(
        G1Point memory p,
        uint256 s
    ) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "ec-mul-failed");
    }

    /**
     *  @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[2] memory p1 = [a1, b1];
        G2Point[2] memory p2 = [a2, b2];

        uint256[12] memory input;

        for (uint256 i = 0; i < 2; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                input,
                mul(12, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }

    /**
     * @notice This function is functionally the same as pairing(), however it specifies a gas limit
     *         the user can set, as a precompile may use the entire gas budget if it reverts.
     */
    function safePairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        uint256 pairingGas
    ) internal view returns (bool, bool) {
        G1Point[2] memory p1 = [a1, b1];
        G2Point[2] memory p2 = [a2, b2];

        uint256[12] memory input;

        for (uint256 i = 0; i < 2; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                pairingGas,
                8,
                input,
                mul(12, 0x20),
                out,
                0x20
            )
        }

        //Out is the output of the pairing precompile, either 0 or 1 based on whether the two pairings are equal.
        //Success is true if the precompile actually goes through (aka all inputs are valid)

        return (success, out[0] != 0);
    }

    /// @return the keccak256 hash of the G1 Point
    /// @dev used for BLS signatures
    function hashG1Point(
        BN254.G1Point memory pk
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(pk.X, pk.Y));
    }


    /**
     * @notice adapted from https://github.com/HarryR/solcrypto/blob/master/contracts/altbn128.sol
     */
    function hashToG1(bytes32 _x) internal view returns (uint256, uint256) {
        uint256 beta = 0;
        uint256 y = 0;

        // XXX: Gen Order (n) or Field Order (p) ?
        uint256 x = uint256(_x) % FP_MODULUS;

        while( true ) {
            (beta, y) = findYFromX(x);

            // y^2 == beta
            if( beta == mulmod(y, y, FP_MODULUS) ) {
                return (x, y);
            }

            x = addmod(x, 1, FP_MODULUS);
        }
        return (0, 0);
    }

    /**
    * Given X, find Y
    *
    *   where y = sqrt(x^3 + b)
    *
    * Returns: (x^3 + b), y
    */
    function findYFromX(uint256 x)
        internal view returns(uint256, uint256)
    {
        // beta = (x^3 + b) % p
        uint256 beta = addmod(mulmod(mulmod(x, x, FP_MODULUS), x, FP_MODULUS), 3, FP_MODULUS);

        // y^2 = x^3 + b
        // this acts like: y = sqrt(beta) = beta^((p+1) / 4)
        uint256 y = expMod(beta, 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52, FP_MODULUS);

        return (beta, y);
    }

    function expMod(uint256 _base, uint256 _exponent, uint256 _modulus) internal view returns (uint256 retval) {
        bool success;
        uint256[1] memory output;
        uint[6] memory input;
        input[0] = 0x20;        // baseLen = new(big.Int).SetBytes(getData(input, 0, 32))
        input[1] = 0x20;        // expLen  = new(big.Int).SetBytes(getData(input, 32, 32))
        input[2] = 0x20;        // modLen  = new(big.Int).SetBytes(getData(input, 64, 32))
        input[3] = _base;
        input[4] = _exponent;
        input[5] = _modulus;
        assembly {
            success := staticcall(sub(gas(), 2000), 5, input, 0xc0, output, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return output[0];
    }
}

pragma solidity ^0.8.9;

contract Parser {
    /**
     * @notice Parses data from non-interactive polynomial proofs.
     * @param polys The non-interactive polynomial proofs themselves
     * @param startIndex The byte index from which to begin reading data.
     * @param length The length of data to parse, in bytes.
     * @return provenString The parsed data.
     */
    function parse(bytes[] calldata polys, uint256 startIndex, uint256 length) public pure returns(bytes memory provenString) {
        // each symbol encodes 31 bytes, and is padded to 32 bytes -- this verifies that we are beginning to parse the data from a non-padded byte
        require(startIndex % 32 != 0, "Cannot start reading from a padded byte");
        // index of the `polys` array from which we are currently reading
        uint256 polyIndex = 0;
        // keeps track of the index to read inside of the current polynomial
        uint256 index = startIndex;
        // continue reading until we reach the desired length
        while(provenString.length < length) {
            /**
             * Read:
             * 1) until the beginning of the next 32 byte segment OR
             * 2) however many more bytes there are left in the fraud string
             * -- whichever amount is the *smallest*
             */
            uint256 bytesToRead = min(
            // the amount of bytes until the end of the current 32 byte segment
                (32 * ((index / 32) + 1)) - index,
            // the remaining total bytes to parse
                length - provenString.length
            );
            /**
             * Append the read bytes to the end of the proven string.
             * Note that indexing of bytes is inclusive of the first index and exclusive of the second, meaning
             * that, for example, polys[0][x:x+1] specifies the *single byte* at position x of `polys[0]`, and
             * polys[0][x:x] will specify an empty byte string.
             */
            provenString = abi.encodePacked(provenString, polys[polyIndex][index:index+bytesToRead]);
            // if we finished reading the current polynomial, then we move onto the next one
            if (index + bytesToRead == polys[polyIndex].length) {
                polyIndex++;
                // skip the first byte of the polynomial since this is zero padding
                index = 1;
                // we have read `index + bytesToRead` bytes, and add 1 more to skip the zero-padding byte at the beginning of every 32 bytes
            } else {
                index += bytesToRead + 1;
            }
        }
        return provenString;
    }

    /// @notice Calculates the minimum of 2 numbers
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return (a < b) ? a : b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IServiceManager.sol";
import "./IDelayedService.sol";
import "./IEigenLayrDelegation.sol";
import "./IDataLayrPaymentManager.sol";

interface IDataLayrServiceManager is IServiceManager, IDelayedService {
    //Relevant metadata for a given datastore
    struct DataStoreMetadata {
        bytes32 headerHash; // the hash of the header as defined in the contract
        uint32 durationDataStoreId; // the id of the datastore relative to all other datastores of the same duration
        uint32 globalDataStoreId; // the id of the datastore relative to all other datastores
        uint32 referenceBlockNumber; // the block number from which the stakes were taken for the datastore
        uint32 blockNumber; // the block number at the time of initialization
        uint96 fee; // the amount of paymentToken paid for the datastore
        address confirmer; // the address that is allowed to confirm the datastore
        bytes32 signatoryRecordHash; // the hash of relavent signatory information for payments and fraud proofs
    }

    //Stores the data required to index a given datastore's metadata
    struct DataStoreSearchData {
        DataStoreMetadata metadata;
        uint8 duration;
        uint256 timestamp;
        uint32 index;
    }

    struct SignatoryRecordMinusDataStoreId {
        bytes32[] nonSignerPubkeyHashes;
        uint256 signedStakeFirstQuorum;
        uint256 signedStakeSecondQuorum;
    }

    struct DataStoresForDuration {
        uint32 one_duration;
        uint32 two_duration;
        uint32 three_duration;
        uint32 four_duration;
        uint32 five_duration;
        uint32 six_duration;
        uint32 seven_duration;
        uint32 dataStoreId;
        uint32 latestTime;
    }

    struct DataStoreHashInputs {
        bytes32 headerHash;
        uint32 dataStoreId;
        uint32 blockNumber;
        uint256 fee;
    }

    /**
     * @notice This function is used for
     * - notifying via Ethereum that the disperser has asserted the data blob
     * into DataLayr and is waiting to obtain quorum of DataLayr operators to sign,
     * - asserting the metadata corresponding to the data asserted into DataLayr
     * - escrow the service fees that DataLayr operators will receive from the disperser
     * on account of their service.
     *
     * This function returns the index of the data blob in dataStoreIdsForDuration[duration][block.timestamp]
     */
    /**
     * @param feePayer is the address that will be paying the fees for this datastore. check DataLayrPaymentManager for further details
     * @param confirmer is the address that must confirm the datastore
     * @param header is the summary of the data that is being asserted into DataLayr,
     *  type DataStoreHeader struct {
     *   KzgCommit      [64]byte
     *   Degree         uint32
     *   NumSys         uint32
     *   NumPar         uint32
     *   OrigDataSize   uint32
     *   Disperser      [20]byte
     *   LowDegreeProof [64]byte
     *  }
     * @param duration for which the data has to be stored by the DataLayr operators.
     * This is a quantized parameter that describes how many factors of DURATION_SCALE
     * does this data blob needs to be stored. The quantization process comes from ease of
     * implementation in DataLayrBombVerifier.sol.
     * @param blockNumber is the block number in Ethereum for which the confirmation will
     * consult total + operator stake amounts.
     * -- must not be more than 'BLOCK_STALE_MEASURE' (defined in DataLayr) blocks in past
     * @return index The index in the array `dataStoreHashesForDurationAtTimestamp[duration][block.timestamp]` at which the DataStore's hash was stored.
     */
    function initDataStore(
        address feePayer,
        address confirmer,
        uint8 duration,
        uint32 blockNumber,
        uint32 totalOperatorsIndex,
        bytes calldata header
    )
        external
        returns (uint32);

    /**
     * @notice This function is used for
     * - disperser to notify that signatures on the message, comprising of hash( headerHash ),
     * from quorum of DataLayr nodes have been obtained,
     * - check that the aggregate signature is valid,
     * - and check whether quorum has been achieved or not.
     */
    /**
     * @param data Input to the `checkSignatures` function, which is of the format:
     * <
     * bytes32 msgHash,
     * uint48 index of the totalStake corresponding to the dataStoreId in the 'totalStakeHistory' array of the BLSRegistry
     * uint32 numberOfNonSigners,
     * uint256[numberOfSigners][4] pubkeys of nonsigners,
     * uint32 apkIndex,
     * uint256[4] apk,
     * uint256[2] sigma
     * >
     */
    function confirmDataStore(bytes calldata data, DataStoreSearchData memory searchData) external;

    /// @notice number of leaves in the root tree
    function numPowersOfTau() external view returns (uint48);

    /// @notice number of layers in the root tree
    function log2NumPowersOfTau() external view returns (uint48);

    /// @notice Unit of measure (in time) for the duration of DataStores
    function DURATION_SCALE() external view returns (uint256);

    /// @notice The longest allowed duation of a DataStore, measured in `DURATION_SCALE`
    function MAX_DATASTORE_DURATION() external view returns (uint8);

    /// @notice Returns the hash of the `index`th DataStore with the specified `duration` at the specified UTC `timestamp`.
    function getDataStoreHashesForDurationAtTimestamp(uint8 duration, uint256 timestamp, uint32 index)
        external
        view
        returns (bytes32);

    /**
     * @notice returns the number of data stores for the @param duration
     */
    function getNumDataStoresForDuration(uint8 duration) external view returns (uint32);

    /// @notice Collateral token used for placing collateral on challenges & payment commits
    function collateralToken() external view returns (IERC20);

    /**
     * @notice contract used for handling payment challenges
     */
    function dataLayrPaymentManager() external view returns (IDataLayrPaymentManager);

    /**
     * @notice Checks that the hash of the `index`th DataStore with the specified `duration` at the specified UTC `timestamp` matches the supplied `metadata`.
     * Returns 'true' if the metadata matches the hash, and 'false' otherwise.
     */
   function verifyDataStoreMetadata(uint8 duration, uint256 timestamp, uint32 index, DataStoreMetadata memory metadata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IDelegationTerms.sol";

/**
 * @title The interface for the primary delegation contract for EigenLayr.
 * @author Layr Labs, Inc.
 * @notice  This is the contract for delegation in EigenLayr. The main functionalities of this contract are
 * - enabling anyone to register as an operator in EigenLayr
 * - allowing new operators to provide a DelegationTerms-type contract, which may mediate their interactions with stakers who delegate to them
 * - enabling any staker to delegate its stake to the operator of its choice
 * - enabling a staker to undelegate its assets from an operator (performed as part of the withdrawal process, initiated through the InvestmentManager)
 */
interface IEigenLayrDelegation {

    /**
     * @notice This will be called by an operator to register itself as an operator that stakers can choose to delegate to.
     * @param dt is the `DelegationTerms` contract that the operator has for those who delegate to them.
     * @dev An operator can set `dt` equal to their own address (or another EOA address), in the event that they want to split payments
     * in a more 'trustful' manner.
     * @dev In the present design, once set, there is no way for an operator to ever modify the address of their DelegationTerms contract.
     */
    function registerAsOperator(IDelegationTerms dt) external;

    /**
     *  @notice This will be called by a staker to delegate its assets to some operator.
     *  @param operator is the operator to whom staker (msg.sender) is delegating its assets
     */
    function delegateTo(address operator) external;

    /**
     * @notice Delegates from `staker` to `operator`.
     * @dev requires that r, vs are a valid ECSDA signature from `staker` indicating their intention for this action
     */
    function delegateToBySignature(address staker, address operator, uint256 expiry, bytes32 r, bytes32 vs) external;

    /**
     * @notice Undelegates `staker` from the operator who they are delegated to.
     * @notice Callable only by the InvestmentManager
     * @dev Should only ever be called in the event that the `staker` has no active deposits in EigenLayer.
     */
    function undelegate(address staker) external;

    /// @notice returns the address of the operator that `staker` is delegated to.
    function delegatedTo(address staker) external view returns (address);

    /// @notice returns the DelegationTerms of the `operator`, which may mediate their interactions with stakers who delegate to them.
    function delegationTerms(address operator) external view returns (IDelegationTerms);

    /// @notice returns the total number of shares in `strategy` that are delegated to `operator`.
    function operatorShares(address operator, IInvestmentStrategy strategy) external view returns (uint256);

    /**
     * @notice Increases the `staker`'s delegated shares in `strategy` by `shares, typically called when the staker has further deposits into EigenLayr
     * @dev Callable only by the InvestmentManager
     */
    function increaseDelegatedShares(address staker, IInvestmentStrategy strategy, uint256 shares) external;

    /**
     * @notice Decreases the `staker`'s delegated shares in each entry of `strategies` by its respective `shares[i]`, typically called when the staker withdraws from EigenLayr
     * @dev Callable only by the InvestmentManager
     */
    function decreaseDelegatedShares(
        address staker,
        IInvestmentStrategy[] calldata strategies,
        uint256[] calldata shares
    ) external;

    /// @notice Returns 'true' if `staker` *is* actively delegated, and 'false' otherwise.
    function isDelegated(address staker) external view returns (bool);

    /// @notice Returns 'true' if `staker` is *not* actively delegated, and 'false' otherwise.
    function isNotDelegated(address staker) external returns (bool);

    /// @notice Returns if an operator can be delegated to, i.e. it has called `registerAsOperator`.
    function isOperator(address operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Interface for a middleware / service that may look at past stake amounts.
 * @author Layr Labs, Inc.
 * @notice Specifically, this interface is designed for services that consult stake amounts up to `BLOCK_STALE_MEASURE`
 * blocks in the past. This may be necessary due to, e.g., network processing & communication delays, or to avoid race conditions
 * that could be present with coordinating aggregate operator signatures while service operators are registering & de-registering.
 * @dev To clarify edge cases, the middleware can look `BLOCK_STALE_MEASURE` blocks into the past, i.e. it may trust stakes from the interval
 * [block.number - BLOCK_STALE_MEASURE, block.number] (specifically, *inclusive* of the block that is `BLOCK_STALE_MEASURE` before the current one)
 */
interface IDelayedService {
    /// @notice The maximum amount of blocks in the past that the service will consider stake amounts to still be 'valid'.
    function BLOCK_STALE_MEASURE() external view returns(uint32);    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEigenLayrDelegation.sol";

/**
 * @title Interface for a `ServiceManager`-type contract.
 * @author Layr Labs, Inc.
 */
// TODO: provide more functions for this spec
interface IServiceManager {
    /// @notice Returns the current 'taskNumber' for the middleware
    function taskNumber() external view returns (uint32);

    /// @notice Permissioned function that causes the ServiceManager to freeze the operator on EigenLayer, through a call to the Slasher contract
    function freezeOperator(address operator) external;

    /// @notice Permissioned function to have the ServiceManager forward a call to the slasher, recording an initial stake update (on operator registration)
    function recordFirstStakeUpdate(address operator, uint32 serveUntil) external;

    /// @notice Permissioned function to have the ServiceManager forward a call to the slasher, recording a stake update
    function recordStakeUpdate(address operator, uint32 updateBlock, uint32 serveUntil, uint256 prevElement) external;

    /// @notice Permissioned function to have the ServiceManager forward a call to the slasher, recording a final stake update (on operator deregistration)
    function recordLastStakeUpdateAndRevokeSlashingAbility(address operator, uint32 serveUntil) external;

    /// @notice Collateral token used for placing collateral on challenges & payment commits
    function collateralToken() external view returns (IERC20);

    /// @notice The Delegation contract of EigenLayer.
    function eigenLayrDelegation() external view returns (IEigenLayrDelegation);

    /// @notice Returns the `latestTime` until which operators must serve.
    function latestTime() external view returns (uint32);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IPaymentManager.sol";
import "./IDataLayrServiceManager.sol";

/**
 * @title Minimal interface extension to `IPaymentManager`.
 * @author Layr Labs, Inc.
 * @notice Adds a single DataLayr-specific function to the base interface.
 */
interface IDataLayrPaymentManager is IPaymentManager {
    /**
     * @notice Used to perform the final step in a payment challenge, in which the 'trueAmount' is determined and the winner of the challenge is decided.
     * This function is called by a party after the other party has bisected the challenged payments to a difference of one, i.e., further bisection
     * is not possible. Once the payments can no longer be bisected, the function resolves the challenge by determining who is wrong.
     * @param stakeHistoryIndex is used as an input to `registry.checkOperatorInactiveAtBlockNumber` -- see that function's documentation
     */
    function respondToPaymentChallengeFinal(
        address operator,
        uint256 stakeIndex,
        uint48 nonSignerIndex,
        bytes32[] memory nonSignerPubkeyHashes,
        TotalStakes calldata totalStakesSigned,
        IDataLayrServiceManager.DataStoreSearchData calldata searchData,
        uint256 stakeHistoryIndex
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IInvestmentStrategy.sol";

/**
 * @title Abstract interface for a contract that helps structure the delegation relationship.
 * @author Layr Labs, Inc.
 * @notice The gas budget provided to this contract in calls from EigenLayr contracts is limited.
 */
//TODO: discuss if we can structure the inputs of these functions better
interface IDelegationTerms {
    function payForService(IERC20 token, uint256 amount) external payable;

    function onDelegationWithdrawn(
        address delegator,
        IInvestmentStrategy[] memory investorStrats,
        uint256[] memory investorShares
    ) external;

    // function onDelegationReceived(
    //     address delegator,
    //     uint256[] memory investorShares
    // ) external;

    function onDelegationReceived(
        address delegator,
        IInvestmentStrategy[] memory investorStrats,
        uint256[] memory investorShares
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Minimal interface for an `InvestmentStrategy` contract.
 * @author Layr Labs, Inc.
 * @notice Custom `InvestmentStrategy` implementations may expand extensively on this interface.
 */
interface IInvestmentStrategy {
    /**
     * @notice Used to deposit tokens into this InvestmentStrategy
     * @param token is the ERC20 token being deposited
     * @param amount is the amount of token being deposited
     * @dev This function is only callable by the investmentManager contract. It is invoked inside of the investmentManager's
     * `depositIntoStrategy` function, and individual share balances are recorded in the investmentManager as well.
     * @return newShares is the number of new shares issued at the current exchange ratio.
     */
    function deposit(IERC20 token, uint256 amount) external returns (uint256);

    /**
     * @notice Used to withdraw tokens from this InvestmentStrategy, to the `depositor`'s address
     * @param token is the ERC20 token being transferred out
     * @param amountShares is the amount of shares being withdrawn
     * @dev This function is only callable by the investmentManager contract. It is invoked inside of the investmentManager's
     * other functions, and individual share balances are recorded in the investmentManager as well.
     */
    function withdraw(address depositor, IERC20 token, uint256 amountShares) external;

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function sharesToUnderlying(uint256 amountShares) external returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function underlyingToShares(uint256 amountUnderlying) external view returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications
     */
    function userUnderlying(address user) external returns (uint256);

     /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function sharesToUnderlyingView(uint256 amountShares) external view returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function underlyingToSharesView(uint256 amountUnderlying) external view returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications
     */
    function userUnderlyingView(address user) external view returns (uint256);

    /// @notice The underyling token for shares in this InvestmentStrategy
    function underlyingToken() external view returns (IERC20);

    /// @notice The total number of extant shares in thie InvestmentStrategy
    function totalShares() external view returns (uint256);

    /// @notice Returns either a brief string explaining the strategy's goal & purpose, or a link to metadata that explains in more detail.
    function explanation() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for a `PaymentManager` contract.
 * @author Layr Labs, Inc.
 */
interface IPaymentManager {
    enum DissectionType {
        INVALID,
        FIRST_HALF,
        SECOND_HALF
    }
    enum PaymentStatus {
        REDEEMED,
        COMMITTED,
        CHALLENGED
    }
    enum ChallengeStatus {
        RESOLVED,
        OPERATOR_TURN,
        CHALLENGER_TURN,
        OPERATOR_TURN_ONE_STEP,
        CHALLENGER_TURN_ONE_STEP
    }

    /**
     * @notice used for storing information on the most recent payment made to the operator
     */
    struct Payment {
        // taskNumber starting from which payment is being claimed
        uint32 fromTaskNumber;
        // taskNumber until which payment is being claimed (exclusive)
        uint32 toTaskNumber;
        // recording when the payment will optimistically be confirmed; used for fraudproof period
        uint32 confirmAt;
        // payment for range [fromTaskNumber, toTaskNumber)
        /// @dev max 1.3e36, keep in mind for token decimals
        uint96 amount;
        /**
         * @notice The possible statuses are:
         * - 0: REDEEMED,
         * - 1: COMMITTED,
         * - 2: CHALLENGED
         */
        PaymentStatus status;
        uint256 collateral; //account for if collateral changed
    }

    /**
     * @notice used for storing information on the payment challenge as part of the interactive process
     */
    struct PaymentChallenge {
        // operator whose payment claim is being challenged,
        address operator;
        // the entity challenging with the fraudproof
        address challenger;
        // address of the service manager contract
        address serviceManager;
        // the TaskNumber from which payment has been computed
        uint32 fromTaskNumber;
        // the TaskNumber until which payment has been computed to
        uint32 toTaskNumber;
        // reward amount the challenger claims is for the first half of tasks
        uint96 amount1;
        // reward amount the challenger claims is for the second half of tasks
        uint96 amount2;
        // used for recording the time when challenge was created
        uint32 settleAt; // when committed, used for fraudproof period
        // indicates the status of the challenge
        /**
         * @notice The possible statuses are:
         * - 0: RESOLVED,
         * - 1: operator turn (dissection),
         * - 2: challenger turn (dissection),
         * - 3: operator turn (one step),
         * - 4: challenger turn (one step)
         */
        ChallengeStatus status;
    }

    struct TotalStakes {
        uint256 signedStakeFirstQuorum;
        uint256 signedStakeSecondQuorum;
    }

    /**
     * @notice deposit one-time fees by the `msg.sender` with this contract to pay for future tasks of this middleware
     * @param onBehalfOf could be the `msg.sender` themselves, or a different address for whom `msg.sender` is depositing these future fees
     * @param amount is amount of futures fees being deposited
     */
    function depositFutureFees(address onBehalfOf, uint256 amount) external;

    /// @notice Allows the `allowed` address to spend up to `amount` of the `msg.sender`'s funds that have been deposited in this contract
    function setAllowance(address allowed, uint256 amount) external;

    /// @notice Used for deducting the fees from the payer to the middleware
    function payFee(address initiator, address payer, uint256 feeAmount) external;

    /**
     * @notice Modifies the `paymentFraudproofCollateral` amount.
     * @param _paymentFraudproofCollateral The new value for `paymentFraudproofCollateral` to take.
     */
    function setPaymentFraudproofCollateral(uint256 _paymentFraudproofCollateral) external;

    /**
     * @notice This is used by an operator to make a claim on the amount that they deserve for their service from their last payment until `toTaskNumber`
     * @dev Once this payment is recorded, a fraud proof period commences during which a challenger can dispute the proposed payment.
     */
    function commitPayment(uint32 toTaskNumber, uint96 amount) external;

    /**
     * @notice Called by an operator to redeem a payment that they previously 'committed' to by calling `commitPayment`.
     * @dev This function can only be called after the challenge window for the payment claim has completed.
     */
    function redeemPayment() external;

    /**
     * @notice This function is called by a fraud prover to challenge a payment, initiating an interactive-type fraudproof.
     * @param operator is the operator against whose payment claim the fraudproof is being made
     * @param amount1 is the reward amount the challenger in that round claims is for the first half of tasks
     * @param amount2 is the reward amount the challenger in that round claims is for the second half of tasks
     *
     */
    function initPaymentChallenge(address operator, uint96 amount1, uint96 amount2) external;

    /**
     * @notice Perform a single bisection step in an existing interactive payment challenge.
     * @param operator The middleware operator who was challenged (used to look up challenge details)
     * @param secondHalf If true, then the caller wishes to challenge the amount claimed as payment in the *second half* of the
     * previous bisection step. If false then the *first half* is indicated instead.
     * @param amount1 The amount that the caller asserts the operator is entitled to, for the first half *of the challenged half* of the previous bisection.
     * @param amount2 The amount that the caller asserts the operator is entitled to, for the second half *of the challenged half* of the previous bisection.
     */
    function performChallengeBisectionStep(address operator, bool secondHalf, uint96 amount1, uint96 amount2)
        external;

    /// @notice resolve an existing PaymentChallenge for an operator
    function resolveChallenge(address operator) external;

    /**
     * @notice Challenge window for submitting fraudproof in the case of an incorrect payment claim by a registered operator.
     */
    function paymentFraudproofInterval() external view returns (uint256);

    /**
     * @notice Specifies the payment that has to be made as a collateral for fraudproof during payment challenges.
     */
    function paymentFraudproofCollateral() external view returns (uint256);

    /// @notice the ERC20 token that will be used by the disperser to pay the service fees to middleware nodes.
    function paymentToken() external view returns (IERC20);

    /// @notice Collateral token used for placing collateral on challenges & payment commits
    function collateralToken() external view returns (IERC20);

    /// @notice Returns the ChallengeStatus for the `operator`'s payment claim.
    function getChallengeStatus(address operator) external view returns (ChallengeStatus);

    /// @notice Returns the 'amount1' for the `operator`'s payment claim.
    function getAmount1(address operator) external view returns (uint96);

    /// @notice Returns the 'amount2' for the `operator`'s payment claim.
    function getAmount2(address operator) external view returns (uint96);

    /// @notice Returns the 'toTaskNumber' for the `operator`'s payment claim.
    function getToTaskNumber(address operator) external view returns (uint48);

    /// @notice Returns the 'fromTaskNumber' for the `operator`'s payment claim.
    function getFromTaskNumber(address operator) external view returns (uint48);

    /// @notice Returns the task number difference for the `operator`'s payment claim.
    function getDiff(address operator) external view returns (uint48);

    /// @notice Returns the active collateral of the `operator` placed on their payment claim.
    function getPaymentCollateral(address) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENCED
// Adapted from OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

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
library Merkle {
    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. The tree is built assuming `leaf` is 
     * the 0 indexed `index`'th leaf from the bottom left of the tree.
     * 
     * Note this is for a Merkle tree using the keccak/sha3 hash function
     */
    function verifyInclusionKeccak(
        bytes memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) internal pure returns (bool) {
        return processInclusionProofKeccak(proof, leaf, index) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. The tree is built assuming `leaf` is 
     * the 0 indexed `index`'th leaf from the bottom left of the tree.
     * 
     * _Available since v4.4._
     * 
     * Note this is for a Merkle tree using the keccak/sha3 hash function
     */
    function processInclusionProofKeccak(bytes memory proof, bytes32 leaf, uint256 index) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i+=32) {
            if(index % 2 == 0) {
                // if ith bit of index is 0, then computedHash is a left sibling
                assembly {
                    mstore(0x00, computedHash)
                    mstore(0x20, mload(add(proof, i)))
                    computedHash := keccak256(0x00, 0x40)
                    index := div(index, 2)
                }
            } else {
                // if ith bit of index is 1, then computedHash is a right sibling
                assembly {
                    mstore(0x00, mload(add(proof, i)))
                    mstore(0x20, computedHash)
                    computedHash := keccak256(0x00, 0x40)
                    index := div(index, 2)
                }            
            }
        }
        return computedHash;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. The tree is built assuming `leaf` is 
     * the 0 indexed `index`'th leaf from the bottom left of the tree.
     * 
     * Note this is for a Merkle tree using the sha256 hash function
     */
    function verifyInclusionSha256(
        bytes memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) internal view returns (bool) {
        return processInclusionProofSha256(proof, leaf, index) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. The tree is built assuming `leaf` is 
     * the 0 indexed `index`'th leaf from the bottom left of the tree.
     *
     * _Available since v4.4._
     * 
     * Note this is for a Merkle tree using the keccak/sha3 hash function
     */
    function processInclusionProofSha256(bytes memory proof, bytes32 leaf, uint256 index) internal view returns (bytes32) {
        bytes32[1] memory computedHash = [leaf];
        for (uint256 i = 32; i <= proof.length; i+=32) {
            if(index % 2 == 0) {
                // if ith bit of index is 0, then computedHash is a left sibling
                assembly {
                    mstore(0x00, mload(computedHash))
                    mstore(0x20, mload(add(proof, i)))
                    if iszero(staticcall(sub(gas(), 2000), 2, 0x00, 0x40, computedHash, 0x20)) {revert(0, 0)}
                    index := div(index, 2)
                }
            } else {
                // if ith bit of index is 1, then computedHash is a right sibling
                assembly {
                    mstore(0x00, mload(add(proof, i)))
                    mstore(0x20, mload(computedHash))
                    if iszero(staticcall(sub(gas(), 2000), 2, 0x00, 0x40, computedHash, 0x20)) {revert(0, 0)}
                    index := div(index, 2)
                }            
            }
        }
        return computedHash[0];
    }

    /**
     @notice this function returns the merkle root of a tree created from a set of leaves using sha256 as its hash function
     @param leaves the leaves of the merkle tree

     @notice requires the leaves.length is a power of 2
     */ 
    function merkleizeSha256(
        bytes32[] memory leaves
    ) internal pure returns (bytes32) {
        //there are half as many nodes in the layer above the leaves
        uint256 numNodesInLayer = leaves.length / 2;
        //create a layer to store the internal nodes
        bytes32[] memory layer = new bytes32[](numNodesInLayer);
        //fill the layer with the pairwise hashes of the leaves
        for (uint i = 0; i < numNodesInLayer; i++) {
            layer[i] = sha256(abi.encodePacked(leaves[2*i], leaves[2*i+1]));
        }
        //the next layer above has half as many nodes
        numNodesInLayer /= 2;
        //while we haven't computed the root
        while (numNodesInLayer != 0) {
            //overwrite the first numNodesInLayer nodes in layer with the pairwise hashes of their children
            for (uint i = 0; i < numNodesInLayer; i++) {
                layer[i] = sha256(abi.encodePacked(layer[2*i], layer[2*i+1]));
            }
            //the next layer above has half as many nodes
            numNodesInLayer /= 2;
        }
        //the first node in the layer is the root
        return layer[0];
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