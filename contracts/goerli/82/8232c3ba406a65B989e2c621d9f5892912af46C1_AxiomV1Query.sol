// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1State} from "./interfaces/core/IAxiomV1State.sol";
import {IAxiomV1Verifier} from "./interfaces/core/IAxiomV1Verifier.sol";
import {IAxiomV1Query, QUERY_MERKLE_DEPTH} from "./interfaces/IAxiomV1Query.sol";
import {MerkleTree} from "./libraries/MerkleTree.sol";
import "./libraries/configuration/AxiomV1Configuration.sol";

/// @title  AxiomV1Query
/// @notice Axiom smart contract that verifies batch queries into block headers, accounts, and storage slots.
/// @dev    Is a UUPS upgradeable contract.
contract AxiomV1Query is IAxiomV1Query, AxiomV1Access, UUPSUpgradeable {
    using Address for address payable;

    address public axiomAddress; // address of deployed AxiomV1 contract
    address public mmrVerifierAddress; // address of deployed ZKP verifier for MMR query verification

    mapping(bytes32 => bool) public verifiedKeccakResults;
    mapping(bytes32 => bool) public verifiedPoseidonResults;

    uint256 public minQueryPrice;
    uint256 public maxQueryPrice;
    uint32 public queryDeadlineInterval;
    mapping(bytes32 => AxiomQueryMetadata) public queries;

    error BlockHashNotValidatedInCache();
    error BlockMerkleRootDoesNotMatchProof();
    error ProofVerificationFailed();
    error MMRProofVerificationFailed();
    error MMREndBlockNotRecent();
    error BlockHashWitnessNotRecent();
    error ClaimedMMRDoesNotMatchRecent();

    error HistoricalMMRKeccakDoesNotMatchProof();   
    error KeccakQueryResponseDoesNotMatchProof();

    error QueryNotInactive();
    error PriceNotPaid();
    error PriceTooHigh();
    error CannotRefundIfNotActive();
    error CannotRefundBeforeDeadline();
    error CannotFulfillIfNotActive();

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @notice Prevents the implementation contract from being initialized outside of the upgradeable proxy.
    constructor() {
        _disableInitializers();
    }

    function initialize(address _axiomAddress, address _mmrVerifierAddress, uint256 _minQueryPrice, uint256 _maxQueryPrice, uint32 _queryDeadlineInterval, address timelock, address guardian)
        public
        initializer
    {
        __UUPSUpgradeable_init();
        __AxiomV1Access_init_unchained();

        require(_axiomAddress != address(0), "AxiomV1Query: Axiom address is zero");
        require(_mmrVerifierAddress != address(0), "AxiomV1Query: MMR verifier address is zero");
        require(timelock != address(0), "AxiomV1Query: timelock address is zero");
        require(guardian != address(0), "AxiomV1Query: guardian address is zero");

        axiomAddress = _axiomAddress;
        mmrVerifierAddress = _mmrVerifierAddress;
        emit UpdateAxiomAddress(_axiomAddress);
        emit UpdateMMRVerifierAddress(_mmrVerifierAddress);

        minQueryPrice = _minQueryPrice;
        maxQueryPrice = _maxQueryPrice;
        queryDeadlineInterval = _queryDeadlineInterval;
        emit UpdateMinQueryPrice(_minQueryPrice);
        emit UpdateMaxQueryPrice(_maxQueryPrice);
        emit UpdateQueryDeadlineInterval(_queryDeadlineInterval);

        // prover is initialized to the contract deployer
        _grantRole(PROVER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(TIMELOCK_ROLE, timelock);
        _grantRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Updates the address of the AxiomV1Core contract used to validate blockhashes, governed by a 'timelock'.
    /// @param  _axiomAddress the new address
    function updateAxiomAddress(address _axiomAddress) external onlyRole(TIMELOCK_ROLE) {
        axiomAddress = _axiomAddress;
        emit UpdateAxiomAddress(_axiomAddress);
    }

    /// @notice Updates the address of the MMR SNARK verifier contract, governed by a 'timelock'.
    /// @param  _mmrVerifierAddress the new address
    function updateMMRVerifierAddress(address _mmrVerifierAddress) external onlyRole(TIMELOCK_ROLE) {
        mmrVerifierAddress = _mmrVerifierAddress;
        emit UpdateMMRVerifierAddress(_mmrVerifierAddress);
    }

    /// @notice Set the price of a query, governed by a 'timelock'.
    /// @param  _minQueryPrice query price in wei
    function updateMinQueryPrice(uint256 _minQueryPrice) external onlyRole(TIMELOCK_ROLE) {
        minQueryPrice = _minQueryPrice;
        emit UpdateMinQueryPrice(_minQueryPrice);
    }

    /// @notice Set the price of a query, governed by a 'timelock'.
    /// @param  _maxQueryPrice query price in wei
    function updateMaxQueryPrice(uint256 _maxQueryPrice) external onlyRole(TIMELOCK_ROLE) {
        maxQueryPrice = _maxQueryPrice;
        emit UpdateMaxQueryPrice(_maxQueryPrice);
    }    

    /// @notice Set the query deadline interval, governed by a 'timelock'.
    /// @param  _queryDeadlineInterval interval in blocks
    function updateQueryDeadlineInterval(uint32 _queryDeadlineInterval) external onlyRole(TIMELOCK_ROLE) {
        queryDeadlineInterval = _queryDeadlineInterval;
        emit UpdateQueryDeadlineInterval(_queryDeadlineInterval);
    }

    function verifyResultVsMMR(
        uint32 mmrIdx,
        RecentMMRWitness calldata mmrWitness, 
        bytes calldata proof) external onlyProver {
        requireNotFrozen();
        _verifyResultVsMMR(mmrIdx, mmrWitness, proof);
    }

    function sendQuery(bytes32 keccakQueryResponse, address payable refundee, bytes calldata query) external payable {
        requireNotFrozen();
        // Check for minimum payment        
        if (msg.value < minQueryPrice) {
            revert PriceNotPaid();
        }
        // Check for maximum payment
        if (msg.value > maxQueryPrice) {
            revert PriceTooHigh();
        }
        _sendQuery(keccakQueryResponse, msg.value, refundee);
        bytes32 queryHash = keccak256(query);
        emit QueryInitiatedOnchain(keccakQueryResponse, msg.value, uint32(block.number) + queryDeadlineInterval, refundee, queryHash);
    }

    function sendOffchainQuery(bytes32 keccakQueryResponse, address payable refundee, bytes32 ipfsHash) external payable {
        requireNotFrozen();
        // Check for minimum payment        
        if (msg.value < minQueryPrice) {
            revert PriceNotPaid();
        }
        // Check for maximum payment
        if (msg.value > maxQueryPrice) {
            revert PriceTooHigh();
        }        
        _sendQuery(keccakQueryResponse, msg.value, refundee);
        emit QueryInitiatedOffchain(keccakQueryResponse, msg.value, uint32(block.number) + queryDeadlineInterval, refundee, ipfsHash);        
    }

    function fufillQueryVsMMR(
        bytes32 keccakQueryResponse, 
        address payable payee, 
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,
        bytes calldata proof
    ) external onlyProver {
        requireNotFrozen();

        if (queries[keccakQueryResponse].state != AxiomQueryState.Active) {
            revert CannotFulfillIfNotActive();
        }

        bytes32 proofKeccakQueryResponse = _verifyResultVsMMR(mmrIdx, mmrWitness, proof);

        if (proofKeccakQueryResponse != keccakQueryResponse) {
            revert KeccakQueryResponseDoesNotMatchProof();
        }

        AxiomQueryMetadata memory newMetadata = AxiomQueryMetadata({
            payment:queries[keccakQueryResponse].payment,
            state:AxiomQueryState.Fulfilled,
            deadlineBlockNumber:queries[keccakQueryResponse].deadlineBlockNumber,
            refundee:queries[keccakQueryResponse].refundee
        });
        queries[keccakQueryResponse] = newMetadata;

        payee.sendValue(queries[keccakQueryResponse].payment);
        emit QueryFulfilled(keccakQueryResponse, queries[keccakQueryResponse].payment, payee);
    }

    function collectRefund(bytes32 keccakQueryResponse) external {
        AxiomQueryMetadata memory queryMetadata = queries[keccakQueryResponse];
        if (queryMetadata.state != AxiomQueryState.Active) {
            revert CannotRefundIfNotActive();
        }
        if (block.number <= queryMetadata.deadlineBlockNumber) {
            revert CannotRefundBeforeDeadline();
        }

        AxiomQueryMetadata memory newMetadata = AxiomQueryMetadata({
            payment:0,
            state:AxiomQueryState.Inactive,
            deadlineBlockNumber:0,
            refundee:payable(address(0))
        });
        queries[keccakQueryResponse] = newMetadata;

        queryMetadata.refundee.sendValue(queryMetadata.payment);
        emit QueryRefunded(keccakQueryResponse, queryMetadata.payment, queryMetadata.deadlineBlockNumber, queryMetadata.refundee);
    }            

    function isKeccakResultValid(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse)
        external
        view
        returns (bool) 
    {
        return verifiedKeccakResults[keccak256(abi.encodePacked(keccakBlockResponse, keccakAccountResponse, keccakStorageResponse))];
    }

    function isPoseidonResultValid(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse)
        external
        view
        returns (bool) 
    {
        return verifiedPoseidonResults[keccak256(abi.encodePacked(poseidonBlockResponse, poseidonAccountResponse, poseidonStorageResponse))];
    }    

    function areResponsesValid(
        bytes32 keccakBlockResponse,
        bytes32 keccakAccountResponse,
        bytes32 keccakStorageResponse,
        BlockResponse[] calldata blockResponses,
        AccountResponse[] calldata accountResponses,
        StorageResponse[] calldata storageResponses
    ) external view returns (bool) {
        if (!verifiedKeccakResults[keccak256(abi.encodePacked(keccakBlockResponse, keccakAccountResponse, keccakStorageResponse))]) {
            return false;
        }

        for (uint32 idx = 0; idx < blockResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                blockResponses[idx].blockHash,
                blockResponses[idx].blockNumber
            ));
            if (!isMerklePathValid(keccakBlockResponse, leaf, blockResponses[idx].proof, blockResponses[idx].leafIdx)) {
                return false;
            }
        }

        // `keccakAccountResponse` is the Merkle root of the packed addresses:
        //    * `keccak(blockNumber . addr . keccak(nonce . balance . storageRoot . codeHash))`.
        for (uint32 idx = 0; idx < accountResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                accountResponses[idx].blockNumber,
                accountResponses[idx].addr,
                keccak256(abi.encodePacked(
                    accountResponses[idx].nonce,
                    accountResponses[idx].balance,
                    accountResponses[idx].storageRoot,
                    accountResponses[idx].codeHash
                ))
            ));
            if (!isMerklePathValid(keccakAccountResponse, leaf, accountResponses[idx].proof, accountResponses[idx].leafIdx)) {
                return false;
            }
        }

        for (uint32 idx = 0; idx < storageResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                storageResponses[idx].blockNumber,
                storageResponses[idx].addr,
                storageResponses[idx].slot,
                storageResponses[idx].value
            ));
            if (!isMerklePathValid(keccakStorageResponse, leaf, storageResponses[idx].proof, storageResponses[idx].leafIdx)) {
                return false;
            }
        }
        return true;            
    } 

    /// @notice Record on-chain query.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The payment offered, in wei.
    /// @param  refundee The address to send any refund to.
    function _sendQuery(bytes32 keccakQueryResponse, uint256 payment, address payable refundee) internal {
        if (queries[keccakQueryResponse].state != AxiomQueryState.Inactive) {
            revert QueryNotInactive();
        }

        AxiomQueryMetadata memory queryMetadata = AxiomQueryMetadata({
            payment:payment,
            state:AxiomQueryState.Active,
            deadlineBlockNumber:uint32(block.number) + queryDeadlineInterval,
            refundee:refundee
        });
        queries[keccakQueryResponse] = queryMetadata;   
    }

    /// @notice Verify a query result on-chain.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function _verifyResultVsMMR(
        uint32 mmrIdx,
        RecentMMRWitness calldata mmrWitness,
        bytes calldata proof
    ) internal returns (bytes32) {
        requireNotFrozen(); 
        require(mmrIdx < MMR_RING_BUFFER_SIZE);

        AxiomMMRQueryResponse memory response = getMMRQueryData(proof);        

        // Check that the historical MMR matches a cached value in `mmrRingBuffer`
        if (IAxiomV1State(axiomAddress).mmrRingBuffer(mmrIdx) != response.historicalMMRKeccak) {
            revert HistoricalMMRKeccakDoesNotMatchProof();
        }

        // recentMMRKeccak = keccak(mmr[0] . mmr[1] . ... . mmr[9]), where mmr[idx] is either bytes32(0) or the Merkle root of 2 ** idx hashes
        // historicalRoots(startBlockNumber) = keccak256(prevHash . root . numFinal) 
        //         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
        //             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
        //             hash(i) = bytes32(0x0) if i >= numFinal
        // We check that `recentMMRPeaks` is included in `historicalRoots[startBlockNumber].root` via `mmrComplementOrPeaks`
        // This proves that all block hashes committed to in `recentMMRPeaks` are part of the canonical chain.
        {
            bytes32 historicalRoot = IAxiomV1State(axiomAddress).historicalRoots(mmrWitness.startBlockNumber); 
            require(historicalRoot == keccak256(abi.encodePacked(mmrWitness.prevHash, mmrWitness.root, mmrWitness.numFinal)));
        }

        require(response.recentMMRKeccak == keccak256(abi.encodePacked(mmrWitness.recentMMRPeaks)));
        uint32 mmrLen = 0;
        for (uint32 idx = 0; idx < 10; idx++) {
            if (mmrWitness.recentMMRPeaks[idx] != bytes32(0)) {
                mmrLen = mmrLen + uint32(1 << idx);
            }
        }

        // if `mmrLen == 0`, there is no check necessary against blocks
        if (mmrLen > 0 && mmrLen <= mmrWitness.numFinal) {
            // In this case, the full `mmrWitness` should be committed to in `mmrWitness.root`
            // In this branch, `mmrWitness.mmrComplementOrPeaks` holds the complementary MMR which completes `mmrWitness`
            // We check that 
            //    * The MMR in `mmrWitness` can be completed to `mmrWitness.root`
            // This proves that the MMR in `mmrWitness` is the MMR of authentic block hashes with 0's appended.
            // Under the random oracle assumption, 0 can never be achieved as keccak of an erroenous block header,
            // so there is no soundness risk here.
            (bytes32 runningHash, ) = getMMRComplementRoot(mmrWitness.recentMMRPeaks, mmrWitness.mmrComplementOrPeaks);
            require(mmrWitness.root == runningHash);            
        } else if (mmrLen > mmrWitness.numFinal) {
            // Some of the claimed block hashes in `mmrWitness` were not committed to in `mmrWitness`
            // In this branch, `mmrWitness.mmrComplementOrPeaks` holds the MMR values of the non-zero hashes in `root`
            // We check that
            //    * block hashes for numbers [startBlockNumber + numFinal, startBlockNumber + mmrLen) are recent
            //    * appending these block hashes to the committed MMR in `mmrWitness` (without 0-padding) yields the MMR in `mmrWitness`
            if (mmrWitness.startBlockNumber + mmrLen > block.number) {
                revert MMREndBlockNotRecent();
            }
            if (mmrWitness.startBlockNumber + mmrWitness.numFinal < block.number - 256) {
                revert BlockHashWitnessNotRecent();
            }

            // zeroHashes[idx] is the Merkle root of a tree of depth idx with 0's as leaves
            bytes32[10] memory zeroHashes = [
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
                bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5),
                bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30),
                bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85),
                bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344),
                bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d),
                bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968),
                bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83),
                bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af),
                bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0)
            ];
            // read the committed MMR without zero-padding
            (bytes32 runningHash, uint32 runningSize) = getMMRComplementRoot(mmrWitness.mmrComplementOrPeaks, zeroHashes);
            require(mmrWitness.numFinal == runningSize);
            require(mmrWitness.root == runningHash);            

            // check appending to the committed MMR with recent blocks will yield the claimed MMR
            {
                bytes32[] memory append = new bytes32[](mmrLen - mmrWitness.numFinal);
                for (uint32 idx = 0; idx < mmrLen - mmrWitness.numFinal; idx++) {
                    append[idx] = blockhash(mmrWitness.startBlockNumber + mmrWitness.numFinal + idx);
                }
                uint32 appendLeft = mmrLen - mmrWitness.numFinal;
                uint32 height = 0;
                uint32 insert = 0;
                while (appendLeft > 0) {
                    insert = (mmrWitness.numFinal >> height) & 1;
                    for (uint32 idx = 0; idx < (appendLeft + insert) / 2; idx++) {
                        bytes32 left;
                        bytes32 right;
                        if (insert == 1) {
                            left = (idx == 0 ? mmrWitness.mmrComplementOrPeaks[height] : append[2 * idx - 1]);
                            right = append[2 * idx];
                        } else {
                            left = append[2 * idx];
                            right = append[2 * idx + 1];
                        }
                        append[idx] = keccak256(abi.encodePacked(left, right));
                    }
                    if ((appendLeft + insert) % 2 == 1) {                  
                        if (append[appendLeft - 1] != mmrWitness.recentMMRPeaks[height]) {
                            revert ClaimedMMRDoesNotMatchRecent();
                        }
                    } else {
                        // This should not be possible, but leaving this revert in for safety.
                        if (mmrWitness.recentMMRPeaks[height] != 0) {
                            revert ClaimedMMRDoesNotMatchRecent();
                        }
                    }
                    height = height + 1;
                    appendLeft = (appendLeft + insert) / 2;
                }
            }
        }

        // verify the ZKP itself
        (bool success, ) = mmrVerifierAddress.call(proof);
        if (!success) {
            revert MMRProofVerificationFailed();
        }

        // update the cache
        bytes32 keccakQueryResponse = keccak256(abi.encodePacked(response.keccakBlockResponse, response.keccakAccountResponse, response.keccakStorageResponse));

        verifiedKeccakResults[keccakQueryResponse] = true;
        verifiedPoseidonResults[keccak256(abi.encodePacked(response.poseidonBlockResponse, response.poseidonAccountResponse, response.poseidonStorageResponse))] = true;
        emit KeccakResultEvent(response.keccakBlockResponse, response.keccakAccountResponse, response.keccakStorageResponse);
        emit PoseidonResultEvent(response.poseidonBlockResponse, response.poseidonAccountResponse, response.poseidonStorageResponse);
        return keccakQueryResponse;
    }

    /// @dev    Given a non-empty MMR `mmr`, compute its `size` and the Merkle root of its completion to 1024 leaves using `mmrComplement`
    /// @param  mmr The peaks of a MMR, where `mmr[idx]` is either `bytes32(0x0)` or the Merkle root of a tree of depth `idx`.  
    ///         At least one peak is guaranteed to be non-zero.
    /// @param  mmrComplement Entries which contain peaks of a complementary MMR, where `mmrComplement[idx]` is either `bytes32(0x0)` or the
    ///         Merkle root of a tree of depth `idx`.  Only the relevant indices are accessed.
    /// @dev    As an example, if `mmr` has peaks of depth 9 8 6 3, then `mmrComplement` has peaks of depth 3 4 5 7
    ///         In this example, the peaks of `mmr` are Merkle roots of the first 2^9 leaves, then the next 2^8 leaves, and so on.
    ///         The peaks of `mmrComplement` are Merkle roots of the first 2^3 leaves after `mmr`, then the next 2^4 leaves, and so on.
    /// @return root The Merkle root of the completion of `mmr`.
    /// @return size The number of leaves contained in `mmr`.
    function getMMRComplementRoot(bytes32[10] memory mmr, bytes32[10] memory mmrComplement) internal pure returns (bytes32 root, uint32 size) {
        bool started = false;
        root = bytes32(0x0);
        size = 0;
        for (uint32 peakIdx = 0; peakIdx < 10; peakIdx++) {
            if (!started && mmr[peakIdx] != bytes32(0x0)) {
                root = mmrComplement[peakIdx];
                started = true;
            }
            if (started) {
                if (mmr[peakIdx] != bytes32(0x0)) {
                    root = keccak256(abi.encodePacked(mmr[peakIdx], root));
                    size = size + uint32(1 << peakIdx);
                } else {
                    root = keccak256(abi.encodePacked(root, mmrComplement[peakIdx]));
                }
            }
        }
    }

    /// @dev   Verify a Merkle inclusion proof into a Merkle tree with (1 << proof.length) leaves
    /// @param root The Merkle root.
    /// @param leaf The claimed leaf in the tree.
    /// @param proof The Merkle proof, where index 0 corresponds to a leaf in the tree.
    /// @param leafIdx The claimed index of the leaf in the tree, where index 0 corresponds to the leftmost leaf.
    function isMerklePathValid(bytes32 root, bytes32 leaf, bytes32[QUERY_MERKLE_DEPTH] memory proof, uint32 leafIdx) internal pure returns (bool) {
        bytes32 runningHash = leaf;
        for (uint32 idx = 0; idx < proof.length; idx++) {
            if ((leafIdx >> idx) & 1 == 0) {
                runningHash = keccak256(abi.encodePacked(runningHash, proof[idx]));
            } else {
                runningHash = keccak256(abi.encodePacked(proof[idx], runningHash));
            }
        }
        return (root == runningHash);
    }

    /// @dev   Extract public instances from proof.
    /// @param proof The ZK proof.
    // The public instances are laid out in the proof calldata as follows:
    //   ** First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
    //   ** The next blocks of 13 groups of 32 bytes each are:
    //   ** `poseidonBlockResponse`            as a field element
    //   ** `keccakBlockResponse`              as 2 field elements, in hi-lo form
    //   ** `poseidonAccountResponse`          as a field element
    //   ** `keccakAccountResponse`            as 2 field elements, in hi-lo form
    //   ** `poseidonStorageResponse`          as a field element
    //   ** `keccakStorageResponse`            as 2 field elements, in hi-lo form
    //   ** `historicalMMRKeccak` which is `keccak256(abi.encodePacked(mmr[10:]))` as 2 field elements in hi-lo form.
    //   ** `recentMMRKeccak`     which is `keccak256(abi.encodePacked(mmr[:10]))` as 2 field elements in hi-lo form.
    // Here:
    //   ** `{keccak, poseidon}{Block, Account, Storage}Response` are defined as in `AxiomMMRQueryResponse`.
    //   ** hi-lo form means a uint256 `(a << 128) + b` is represented as two uint256's `a` and `b`, each of which is
    //      guaranteed to contain a uint128.
    //   ** `mmr` is a variable length array of bytes32 containing the Merkle Mountain Range that `proof` is proving into.
    //      `mmr[idx]` is either `bytes32(0)` or the Merkle root of `1 << idx` block hashes.
    //   ** `mmr` is guaranteed to have length at least `10` and at most `32`.
    function getMMRQueryData(bytes calldata proof)
        internal 
        pure
        returns (AxiomMMRQueryResponse memory)
    {
        return AxiomMMRQueryResponse({
            poseidonBlockResponse:bytes32(proof[384:384 + 32]),
            keccakBlockResponse:bytes32(uint256(bytes32(proof[384 + 32: 384 + 2 * 32])) << 128 | uint256(bytes32(proof[384 + 2 * 32: 384 + 3 * 32]))),
            poseidonAccountResponse:bytes32(proof[384 + 3 * 32:384 + 4 * 32]),
            keccakAccountResponse:bytes32(uint256(bytes32(proof[384 + 4 * 32: 384 + 5 * 32])) << 128 | uint256(bytes32(proof[384 + 5 * 32: 384 + 6 * 32]))),
            poseidonStorageResponse:bytes32(proof[384 + 6 * 32:384 + 7 * 32]),
            keccakStorageResponse:bytes32(uint256(bytes32(proof[384 + 7 * 32: 384 + 8 * 32])) << 128 | uint256(bytes32(proof[384 + 8 * 32: 384 + 9 * 32]))),
            historicalMMRKeccak:bytes32(uint256(bytes32(proof[384 + 9 * 32: 384 + 10 * 32])) << 128 | uint256(bytes32(proof[384 + 10 * 32: 384 + 11 * 32]))),
            recentMMRKeccak:bytes32(uint256(bytes32(proof[384 + 11 * 32: 384 + 12 * 32])) << 128 | uint256(bytes32(proof[384 + 12 * 32: 384 + 13 * 32])))
        });
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool) {
        return interfaceId == type(IAxiomV1Query).interfaceId || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(TIMELOCK_ROLE) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title  Axiom V1 Access
/// @notice Abstract contract controlling permissions of AxiomV1
/// @dev    For use in a UUPS upgradeable contract.
abstract contract AxiomV1Access is Initializable, AccessControlUpgradeable {
    bool public frozen;

    /// @notice Storage slot for the address with the permission of a 'timelock'.
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'guardian'.
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'prover'.
    bytes32 public constant PROVER_ROLE = keccak256("PROVER_ROLE");

    /// @notice Emitted when the `freezeAll` is called
    event FreezeAll();

    /// @notice Emitted when the `unfreezeAll` is called
    event UnfreezeAll();

    /// @notice Error when trying to call contract while it is frozen
    error ContractIsFrozen();

    /// @notice Error when trying to call contract from address without 'prover' role
    error NotProverRole();

    /**
     * @dev Modifier to make a function callable only by the 'prover' role.
     * As an initial safety mechanism, the 'update_' functions are only callable by the 'prover' role.
     * Granting the prover role to `address(0)` will enable this role for everyone.
     */
    modifier onlyProver() {
        if (!hasRole(PROVER_ROLE, address(0)) && !hasRole(PROVER_ROLE, _msgSender())) {
            revert NotProverRole();
        }
        _;
    }

    function __AxiomV1Access_init() internal onlyInitializing {
        __AxiomV1Access_init_unchained();
    }

    function __AxiomV1Access_init_unchained() internal onlyInitializing {
        frozen = false;
    }

    function freezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = true;
        emit FreezeAll();
    }

    function unfreezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = false;
        emit UnfreezeAll();
    }

    /// @notice Checks that the contract is not frozen.
    function requireNotFrozen() internal view {
        if (frozen) {
            revert ContractIsFrozen();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./core/IAxiomV1Verifier.sol";

// The depth of the Merkle root of queries in:
//   `keccakBlockResponse`, `keccakAccountResponse`, and `keccakStorageResponse`
uint32 constant QUERY_MERKLE_DEPTH = 6;

interface IAxiomV1Query {
    /// @notice States of an on-chain query
    /// @param  Inactive The query has not been made or was refunded.
    /// @param  Active The query has been requested, but not fulfilled.
    /// @param  Fulfilled The query was successfully fulfilled.
    enum AxiomQueryState {
        Inactive,
        Active,
        Fulfilled
    }

    /// @notice Stores metadata about a query 
    /// @param  payment The ETH payment received, in wei. 
    /// @param  state The state of the query.
    /// @param  deadlineBlockNumber The deadline (in block number) after which a refund may be granted.
    /// @param  refundee The address funds should be returned to if the query is not fulfilled.
    struct AxiomQueryMetadata {
        uint256 payment;
        AxiomQueryState state; 
        uint32 deadlineBlockNumber;
        address payable refundee;
    }

    /// @notice Response values read from ZK proof for query.
    /// @param  poseidonBlockResponse Poseidon Merkle root of `poseidon(blockHash . blockNumber . poseidon_tree_root(block_header))`
    /// @param  keccakBlockResponse Keccak Merkle root of `keccak(blockHash . blockNumber)` 
    /// @param  poseidonAccountResponse Poseidon Merkle root of `poseidon(poseidonBlockResponseRow . poseidon(stateRoot . addr . poseidon_tree_root(account_state)))`
    /// @param  keccakAccountResponse Keccak Merkle root of `keccak(blockNumber . addr . keccak(nonce . balance . storageRoot . codeHash))`
    /// @param  poseidonStorageResponse Poseidon Merkle root of `poseidon(poseidonBlockResponseRow . poseidonAccountResponseRow . poseidon(storageRoot . slot . value))`
    /// @param  keccakStorageResponse Keccak Merkle root of `keccak(blockNumber . addr . slot . value)`
    /// @param  historicalMMRKeccak `keccak256(abi.encodePacked(mmr[10:]))`
    /// @param  recentMMRKeccak `keccak256(abi.encodePacked(mmr[:10]))`
    //  Detailed documentation on format here: https://hackmd.io/@axiom/S17K2drf2
    //  ** `poseidonBlockResponseRow = poseidon(blockHash . blockNumber . poseidon_tree_root(block_header))`
    //  ** `poseidonAccountResponseRow = poseidon(stateRoot . addr . poseidon_tree_root(account_state)))`
    //  ** `mmr` is a variable length array of bytes32 containing the Merkle Mountain Range the ZK proof is proving into.
    //     `mmr[idx]` is either `bytes32(0)` or the Merkle root of `1 << idx` block hashes.
    //  ** `mmr` is guaranteed to have length at least `10` and at most `32`.
    struct AxiomMMRQueryResponse {
        bytes32 poseidonBlockResponse;
        bytes32 keccakBlockResponse;
        bytes32 poseidonAccountResponse; 
        bytes32 keccakAccountResponse;
        bytes32 poseidonStorageResponse;
        bytes32 keccakStorageResponse;
        bytes32 historicalMMRKeccak;
        bytes32 recentMMRKeccak;
    }

    /// @notice Stores witness data for checking MMRs
    /// @param  prevHash The `prevHash` as in `IAxiomV1State`.
    /// @param  root The `root` as in `IAxiomV1State`.
    /// @param  numFinal The `numFinal` as in `IAxiomV1State`.  
    /// @param  startBlockNumber The `startBlockNumber` as in `IAxiomV1State`.
    /// @param  recentMMRPeaks Peaks of the MMR committed to in the public input `recentMMRKeccak` of the ZK proof.
    /// @param  mmrComplementOrPeaks If `len(recentMMRPeaks) <= numFinal`, then this is a complementary MMR containing  
    ///         the complement of `recentMMRPeaks` which together with `recentMMRPeaks` forms `root`.  
    ///         If `len(recentMMRPeaks) > numFinal`, then this is the MMR peaks of the `numFinal` blockhashes commited
    ///         to in `root`.
    struct RecentMMRWitness {
        bytes32 prevHash;
        bytes32 root;
        uint32 numFinal;
        uint32 startBlockNumber;        
        bytes32[10] recentMMRPeaks;
        bytes32[10] mmrComplementOrPeaks;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  blockHash The block hash.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakBlockResponse`.
    /// @param  proof A Merkle proof into `keccakBlockResponse`.
    struct BlockResponse {
        uint32 blockNumber;
        bytes32 blockHash;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  addr The address.
    /// @param  nonce The nonce.
    /// @param  balance The balance.
    /// @param  storageRoot The storage root.
    /// @param  codeHash The code hash.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakAccountResponse`.
    /// @param  proof A Merkle proof into `keccakAccountResponse`.
    //  Note: Fields are zero-padded by prefixing with zero bytes to:
    //    * `nonce`: 8 bytes
    //    * `balance`: 12 bytes
    //    * `storageRoot`: 32 bytes
    //    * `codeHash`: 32 bytes    
    struct AccountResponse {
        uint32 blockNumber;        
        address addr;
        uint64 nonce;
        uint96 balance;
        bytes32 storageRoot;
        bytes32 codeHash;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }

    /// @notice Store a query result into a single block
    /// @param  blockNumber The block number.
    /// @param  addr The address.
    /// @param  slot The storage slot index. 
    /// @param  value The storage slot value.
    /// @param  leafIdx The position of this result in the Merkle tree committed to by `keccakStorageResponse`.
    /// @param  proof A Merkle proof into `keccakStorageResponse`.
    struct StorageResponse {
        uint32 blockNumber;
        address addr;
        uint256 slot;
        uint256 value;

        uint32 leafIdx;
        bytes32[QUERY_MERKLE_DEPTH] proof;
    }    

    /// @notice Read the set of verified query responses in Keccak form.
    /// @param  hash `verifiedKeccakResults(keccak256(keccakBlockResponse . keccakAccountResponse . keccakStorageResponse)) == true` 
    ///         if and only if each of `keccakBlockResponse`, `keccakAccountResponse`, and `keccakStorageResponse` have been verified
    ///         on-chain by a ZK proof.
    function verifiedKeccakResults(bytes32 hash) external view returns (bool);

    /// @notice Read the set of verified query responses in Poseidon form.
    /// @param  hash `verifiedPoseidonResults(keccak256(poseidonBlockResponse . poseidonAccountResponse . poseidonStorageResponse)) == true` 
    ///         if and only if each of `poseidonBlockResponse`, `poseidonAccountResponse`, and `poseidonStorageResponse` have been
    ///         verified on-chain by a ZK proof.
    function verifiedPoseidonResults(bytes32 hash) external view returns (bool);

    /// @notice Returns the metadata associated to a query
    /// @param  keccakQueryResponse The hash of the query response.
    function queries(bytes32 keccakQueryResponse) external view 
        returns (
            uint256 payment,
            AxiomQueryState state,
            uint32 deadlineBlockNumber,
            address payable refundee
        );

    /// @notice Emitted when the `AxiomV1Core` address is updated.
    /// @param  newAddress The updated address.
    event UpdateAxiomAddress(address newAddress);

    /// @notice Emitted when the batch query verifier address is updated.
    /// @param  newAddress The updated address.
    event UpdateMMRVerifierAddress(address newAddress);

    /// @notice Emitted when a Keccak result is recorded
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    event KeccakResultEvent(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse);

    /// @notice Emitted when a Poseidon result is recorded
    /// @param  poseidonBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonStorageResponse As documented in `AxiomMMRQueryResponse`.
    event PoseidonResultEvent(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse);

    /// @notice Emitted when the `minQueryPrice` is updated.
    /// @param  minQueryPrice The new `minQueryPrice`.
    event UpdateMinQueryPrice(uint256 minQueryPrice);

    /// @notice Emitted when the `maxQueryPrice` is updated.
    /// @param  maxQueryPrice The new `maxQueryPrice`.
    event UpdateMaxQueryPrice(uint256 maxQueryPrice);

    /// @notice Emitted when the `queryDeadlineInterval` is updated.
    /// @param  queryDeadlineInterval The new `queryDeadlineInterval`.
    event UpdateQueryDeadlineInterval(uint32 queryDeadlineInterval);

    /// @notice Emitted when a new query with off-chain data availability is requested.
    /// @param  keccakQueryResponse The hash of the claimed query response.
    /// @param  payment The ETH payment offered, in wei.
    /// @param  deadlineBlockNumber The deadline block number after which a refund is possible.
    /// @param  refundee The address of the refundee.
    /// @param  ipfsHash A content-addressed hash on IPFS where the query spec may be found.
    event QueryInitiatedOffchain(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee, bytes32 ipfsHash);

    /// @notice Emitted when a new query with on-chain data availability is requested.
    /// @param  keccakQueryResponse The hash of the claimed query response.
    /// @param  payment The ETH payment offered, in wei.
    /// @param  deadlineBlockNumber The deadline block number after which a refund is possible.
    /// @param  refundee The address of the refundee.
    /// @param  queryHash The hash of the on-chain query.    
    event QueryInitiatedOnchain(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee, bytes32 queryHash);

    /// @notice Emitted when a query is fulfilled.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The ETH payment collected, in wei.
    /// @param  prover The address of the prover collecting payment.
    event QueryFulfilled(bytes32 keccakQueryResponse, uint256 payment, address prover);

    /// @notice Emitted when a query is refunded.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The ETH payment refunded minus gas, in wei.
    /// @param  refundee The address collecting the refund.    
    event QueryRefunded(bytes32 keccakQueryResponse, uint256 payment, uint32 deadlineBlockNumber, address refundee);

    /// @notice Verify a query result on-chain.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function verifyResultVsMMR(
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,                   
        bytes calldata proof
    ) external;                

    /// @notice Request proof for query with on-chain query data availability.
    /// @param  keccakQueryResponse The Keccak-encoded query response.
    /// @param  refundee The address refunds should be sent to.
    /// @param  query The serialized query.
    function sendQuery(bytes32 keccakQueryResponse, address payable refundee, bytes calldata query) external payable;

    /// @notice Request proof for query with off-chain query data availability.
    /// @param  keccakQueryResponse The Keccak-encoded query response.
    /// @param  refundee The address refunds should be sent to.
    /// @param  ipfsHash The IPFS hash the query should optionally be posted to.
    function sendOffchainQuery(bytes32 keccakQueryResponse, address payable refundee, bytes32 ipfsHash) external payable;

    /// @notice Fulfill a query request on-chain.
    /// @param  keccakQueryResponse The hashed query response.
    /// @param  payee The address to send payment to.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function fufillQueryVsMMR(
        bytes32 keccakQueryResponse, 
        address payable payee, 
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,          
        bytes calldata proof
    ) external;

    /// @notice Trigger refund collection for a query after the deadline has expired.
    /// @param keccakQueryResponse THe hashed query response.
    function collectRefund(bytes32 keccakQueryResponse) external;

    /// @notice Checks whether an unpacked query response has already been verified.
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    function isKeccakResultValid(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse)
        external
        view
        returns (bool);

    /// @notice Checks whether an unpacked query response has already been verified.
    /// @param  poseidonBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  poseidonStorageResponse As documented in `AxiomMMRQueryResponse`.
    function isPoseidonResultValid(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse)
        external
        view
        returns (bool);        

    /// @notice Verify block, account, and storage data against responses which have already been proven.
    /// @param  keccakBlockResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakAccountResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  keccakStorageResponse As documented in `AxiomMMRQueryResponse`.
    /// @param  blockResponses The list of block results.
    /// @param  accountResponses The list of account results.
    /// @param  storageResponses The list of storage results.
    // block_response = keccak(blockHash . blockNumber)
    // account_response = hash(blockNumber . address . hash_tree_root(account_state))
    // storage_response = hash(blockNumber . address . slot . value)
    function areResponsesValid(
        bytes32 keccakBlockResponse,
        bytes32 keccakAccountResponse,
        bytes32 keccakStorageResponse,
        BlockResponse[] calldata blockResponses,
        AccountResponse[] calldata accountResponses,
        StorageResponse[] calldata storageResponses
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1State {
    /// @notice Returns the hash of a batch of consecutive blocks previously verified by the contract
    /// @dev    The reads here will match the emitted #UpdateEvent
    /// @return historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    ///         historicalRoots(startBlockNumber) = 0 if block `startBlockNumber` is not verified
    ///         historicalRoots(startBlockNumber) = keccak256(prevHash || root || numFinal) where || is concatenation
    ///         - prevHash is the parent hash of block `startBlockNumber`
    ///         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
    ///             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///             hash(i) = bytes32(0x0) if i >= numFinal
    ///         - 0 < numFinal <= 1024 is the number of verified consecutive roots in [startBlockNumber, startBlockNumber + numFinal)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    /// @notice Returns metadata about the number of consecutive blocks from genesis stored in the contract
    ///         The Merkle mountain range stores a commitment to the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    /// @return numPeaks = bit_length(len) is the number of peaks in the Merkle mountain range
    /// @return len indicates that the historicalMMR commits to blockhashes of blocks [0, 1024 * len)
    /// @return index the current index in the ring buffer storing commitments to historicalMMRs
    function historicalMMR() external view returns (uint32 numPeaks, uint32 len, uint32 index);

    /// @notice Returns the i-th Merkle root in the historical Merkle Mountain Range
    /// @param  i The index, `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element,
    ///         list is the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    function historicalMMRPeaks(uint32 i) external view returns (bytes32);

    /// @notice A ring buffer storing commitments to past historicalMMR states
    /// @param  index The index in the ring buffer
    function mmrRingBuffer(uint256 index) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BLOCK_BATCH_DEPTH} from "../../libraries/configuration/AxiomV1Configuration.sol";

interface IAxiomV1Verifier {
    /// @notice A merkle proof to verify a block against the verified blocks cached by Axiom
    /// @dev    `BLOCK_BATCH_DEPTH = 10`
    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[BLOCK_BATCH_DEPTH] merkleProof;
    }

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash. Assumes that blockNumber is within the last 256 most recent blocks.
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);

    /// @notice Verify the blockhash of block witness.blockNumber equals witness.claimedBlockHash by checking against Axiom's cache of #historicalRoots.
    /// @dev    For block numbers within the last 256, use #isRecentBlockHashValid instead.
    /// @param  witness The block hash to verify and the Merkle proof to verify it
    ///         witness.blockNumber is the block number to verify
    ///         witness.claimedBlockHash is the claimed blockhash of block witness.blockNumber
    ///         witness.prevHash is the prevHash stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.numFinal is the numFinal stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof is the Merkle inclusion proof of witness.claimedBlockHash to the root stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof[i] is the sibling of the Merkle node at depth 10 - i, for i = 0, ..., 10
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash by checking against Axiom's cache of historical Merkle mountain ranges in #mmrRingBuffer.
    /// @dev    Use event logs to determine the correct bufferId and get the MMR at that index in the ring buffer.
    /// @param  mmr The Merkle mountain range commited to in #mmrRingBuffer(bufferId), must be correct length
    /// @param  bufferId The index in the ring buffer of #mmrRingBuffer
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    /// @param  merkleProof The Merkle inclusion proof of claimedBlockHash to the corresponding peak in mmr. The correct peak is calculated from mmr.length and blockNumber.
    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {HISTORICAL_NUM_ROOTS} from "./configuration/AxiomV1Configuration.sol";

/// @title Merkle Tree
/// @notice Helper functions for computing Merkle roots of Merkle trees
library MerkleTree {
    /// @notice Compute the Merkle root of a Merkle tree with HISTORICAL_NUM_ROOTS leaves
    /// @param  leaves The HISTORICAL_NUM_ROOTS leaves of the Merkle tree
    function merkleRoot(bytes32[HISTORICAL_NUM_ROOTS] memory leaves) internal pure returns (bytes32) {
        // we create a new array to avoid mutating `leaves`, which is passed by reference
        // unnecessary if calldata `leaves` is passed in since it is automatically copied to memory
        bytes32[] memory hashes = new bytes32[](HISTORICAL_NUM_ROOTS / 2);
        for (uint256 i = 0; i < HISTORICAL_NUM_ROOTS / 2; i++) {
            hashes[i] = keccak256(abi.encodePacked(leaves[i << 1], leaves[(i << 1) | 1]));
        }
        uint256 len = HISTORICAL_NUM_ROOTS / 4;
        while (len != 0) {
            for (uint256 i = 0; i < len; i++) {
                hashes[i] = keccak256(abi.encodePacked(hashes[i << 1], hashes[(i << 1) | 1]));
            }
            len >>= 1;
        }
        return hashes[0];
    }

    /// @notice Compute the Merkle root of a Merkle tree with 2^depth leaves all equal to bytes32(0x0)
    /// @param depth The depth of the Merkle tree, 0 <= depth < BLOCK_BATCH_DEPTH.
    function getEmptyHash(uint256 depth) internal pure returns (bytes32) {
        // emptyHashes[idx] is the Merkle root of a tree of depth idx with 0's as leaves
        if (depth == 0) {
            return bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
        } else if (depth == 1) {
            return bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5);
        } else if (depth == 2) {
            return bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30);
        } else if (depth == 3) {
            return bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85);
        } else if (depth == 4) {
            return bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344);
        } else if (depth == 5) {
            return bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d);
        } else if (depth == 6) {
            return bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968);
        } else if (depth == 7) {
            return bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83);
        } else if (depth == 8) {
            return bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af);
        } else if (depth == 9) {
            return bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0);
        } else {
            revert("depth must be in range [0, 10)");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Constants and free functions to be inlined into by AxiomV1Core

// ZK circuit constants:

// AxiomV1 caches blockhashes in batches, stored as Merkle roots of binary Merkle trees
uint32 constant BLOCK_BATCH_SIZE = 1024;
uint32 constant BLOCK_BATCH_DEPTH = 10;

// constants for batch import of historical block hashes
// historical uploads a bigger batch of block hashes, stored as Merkle roots of binary Merkle trees
uint32 constant HISTORICAL_BLOCK_BATCH_SIZE = 131072; // 2 ** 17
uint32 constant HISTORICAL_BLOCK_BATCH_DEPTH = 17;
// we will consider the historical Merkle tree of blocks as a Merkle tree of the block batch roots
uint32 constant HISTORICAL_NUM_ROOTS = 128; // HISTORICAL_BATCH_SIZE / BLOCK_BATCH_SIZE

// The first 4 * 3 * 32 bytes of proof calldata are reserved for two BN254 G1 points for a pairing check
// It will then be followed by (7 + BLOCK_BATCH_DEPTH * 2) * 32 bytes of public inputs/outputs
uint32 constant AUX_PEAKS_START_IDX = 608; // PUBLIC_BYTES_START_IDX + 7 * 32

// Historical MMR Ring Buffer constants
uint32 constant MMR_RING_BUFFER_SIZE = 8;

/// @dev proofData stores bytes32 and uint256 values in hi-lo format as two uint128 values because the BN254 scalar field is 254 bits
/// @dev The first 12 * 32 bytes of proofData are reserved for ZK proof verification data
// Extract public instances from proof
// The public instances are laid out in the proof calldata as follows:
// First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
// 384..384 + 32 * 2: prevHash (32 bytes) as two uint128 cast to uint256, because zk proof uses 254 bit field and cannot fit uint256 into a single element
// 384 + 32 * 2..384 + 32 * 4: endHash (32 bytes) as two uint128 cast to uint256
// 384 + 32 * 4..384 + 32 * 5: startBlockNumber (uint32: 4 bytes) and endBlockNumber (uint32: 4 bytes) are concatenated as `startBlockNumber . endBlockNumber` (8 bytes) and then cast to uint256
// 384 + 32 * 5..384 + 32 * 7: root (32 bytes) as two uint128 cast to uint256, this is the highest peak of the MMR if endBlockNumber - startBlockNumber == 1023, otherwise 0
function getBoundaryBlockData(bytes calldata proofData)
    pure
    returns (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root)
{
    prevHash = bytes32(uint256(bytes32(proofData[384:416])) << 128 | uint256(bytes32(proofData[416:448])));
    endHash = bytes32(uint256(bytes32(proofData[448:480])) << 128 | uint256(bytes32(proofData[480:512])));
    startBlockNumber = uint32(bytes4(proofData[536:540]));
    endBlockNumber = uint32(bytes4(proofData[540:544]));
    root = bytes32(uint256(bytes32(proofData[544:576])) << 128 | uint256(bytes32(proofData[576:608])));
}

// We have a Merkle mountain range of max depth BLOCK_BATCH_DEPTH (so length BLOCK_BATCH_DEPTH + 1 total) ordered in **decreasing** order of peak size, so:
// `root` from `getBoundaryBlockData` is the peak for depth BLOCK_BATCH_DEPTH
// `getAuxMmrPeak(proofData, i)` is the peaks for depth BLOCK_BATCH_DEPTH - 1 - i
// 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): (32 bytes) as two uint128 cast to uint256, same as blockHash
// Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange
function getAuxMmrPeak(bytes calldata proofData, uint256 i) pure returns (bytes32) {
    return bytes32(
        uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64:AUX_PEAKS_START_IDX + i * 64 + 32])) << 128
            | uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64 + 32:AUX_PEAKS_START_IDX + (i + 1) * 64]))
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}