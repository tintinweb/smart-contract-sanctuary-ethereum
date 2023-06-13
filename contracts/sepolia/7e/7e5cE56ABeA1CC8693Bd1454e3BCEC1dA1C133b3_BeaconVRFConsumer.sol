// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "../vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {VRFBeaconTypes} from "../VRFBeaconTypes.sol";
import {ChainSpecificUtil} from "../ChainSpecificUtil.sol";
import {IVRFCoordinatorConsumer} from "../IVRFCoordinatorConsumer.sol";

contract BeaconVRFConsumer is IVRFCoordinatorConsumer {
    bytes internal constant EMPTY_ARGS = "";

    uint256[] public s_randomWords;
    mapping(uint256 => mapping(uint24 => uint256)) /* block height */
        public s_requestsIDs;
    mapping(uint256 => VRFBeaconTypes.BeaconRequest) public s_myBeaconRequests;
    mapping(uint256 => uint256[]) /* randomness */
        public s_ReceivedRandomnessByRequestID;
    bytes public s_arguments;
    uint256 public s_mostRecentRequestID;

    uint64 public s_subId;
    uint256 public s_gasAvailable;
    bool public fail;
    uint256 public i_beaconPeriodBlocks;

    constructor(
        address coordinator,
        bool shouldFail,
        uint256 beaconPeriodBlocks
    ) IVRFCoordinatorConsumer(coordinator) {
        fail = shouldFail;
        i_beaconPeriodBlocks = beaconPeriodBlocks;
    }

    function setFail(bool shouldFail) public {
        fail = shouldFail;
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual override {
        if (fail) {
            require(false, " failed in fulfillRandomWords");
        }
        s_ReceivedRandomnessByRequestID[requestID] = response;
        s_arguments = arguments;
    }

    function testRequestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confDelay,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) public returns (uint256) {
        uint256 periodOffset = ChainSpecificUtil.getBlockNumber() %
            i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = ChainSpecificUtil.getBlockNumber() +
            i_beaconPeriodBlocks -
            periodOffset;
        uint256 externalRequestID = s_coordinator.requestRandomnessFulfillment(
            subID,
            numWords,
            confDelay,
            callbackGasLimit,
            arguments,
            EMPTY_ARGS
        );
        storeBeaconRequest(
            externalRequestID,
            nextBeaconOutputHeight,
            confDelay,
            numWords
        );
        s_mostRecentRequestID = externalRequestID;
        return externalRequestID;
    }

    function testRequestRandomness(
        uint16 numWords,
        uint256 subID,
        uint24 confirmationDelayArg
    ) external returns (uint256) {
        // Have to compute them nextBeaconOutputHeight becuase requestRandomness does not return it
        // XXX : should maybe return it in requestRandomness?

        uint256 periodOffset = ChainSpecificUtil.getBlockNumber() %
            i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = ChainSpecificUtil.getBlockNumber() +
            i_beaconPeriodBlocks -
            periodOffset;
        uint256 requestID = s_coordinator.requestRandomness(
            subID,
            numWords,
            confirmationDelayArg,
            EMPTY_ARGS
        );

        // Need the beaconRequest for computing the expected VRF in the test
        // requestRandomness does not emit or return the beaconRequest, so could not follow after
        // beaconRequests off-chain without accessing it directly from the contract.

        storeBeaconRequest(
            requestID,
            nextBeaconOutputHeight,
            confirmationDelayArg,
            numWords
        );
        s_mostRecentRequestID = requestID;
        return requestID;
    }

    function testRedeemRandomness(uint256 subID, uint256 requestID) public {
        uint256[] memory response = s_coordinator.redeemRandomness(
            subID,
            requestID,
            EMPTY_ARGS
        );
        s_ReceivedRandomnessByRequestID[requestID] = response;
    }

    function storeBeaconRequest(
        uint256 reqId,
        uint256 height,
        uint24 delay,
        uint16 numWords
    ) public {
        s_requestsIDs[height][delay] = reqId;
        uint256 slotNumberBig = height / i_beaconPeriodBlocks;
        uint32 slotNumber = uint32(slotNumberBig);
        VRFBeaconTypes.BeaconRequest memory r = VRFBeaconTypes.BeaconRequest({
            slotNumber: slotNumber,
            confirmationDelay: delay,
            numWords: numWords,
            requester: address(this)
        });
        s_myBeaconRequests[reqId] = r;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECCArithmetic} from "./ECCArithmetic.sol";

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    uint8 public constant NUM_CONF_DELAYS = 8;
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /// @dev With a beacon period of 15, using a uint32 here allows for roughly
    /// @dev 60B blocks, which would take roughly 2000 years on a chain with a 1s
    /// @dev block time.
    uint32 internal constant MAX_SLOT_NUMBER = type(uint32).max;

    uint24 internal constant MAX_CONFIRMATION_DELAY = type(uint24).max;

    /// @dev Request metadata. Designed to fit in a single 32-byte word, to save
    /// @dev on storage/retrieval gas costs.
    struct BeaconRequest {
        uint32 slotNumber;
        uint24 confirmationDelay;
        uint16 numWords;
        address requester; // Address which will eventually retrieve randomness
    }

    struct Callback {
        uint256 requestID;
        uint16 numWords;
        address requester;
        bytes arguments;
        uint96 gasAllowance; // gas offered to callback method when called
        uint256 subID;
        uint256 gasPrice;
        uint256 weiPerUnitLink;
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    /// @dev configuration parameters for billing that change per-report
    /// @dev total size: 256 bits
    struct HotBillingConfig {
        // lastReportTimestamp is the timestamp of the last report.
        uint32 lastReportTimestamp;
        // reasonableGasPriceLastBlockNumber is the block number of the
        // most recently-reported reasonableGasPrice.
        uint64 reasonableGasPriceLastBlockNumber;
        // The average gas price reported by the OCR committee.
        uint64 reasonableGasPrice;
        // Most recent LINK/ETH ratio.
        uint96 weiPerUnitLink;
    }

    /// @dev configuration parameters for the coordinator including billing
    /// @dev total size: 243 bits
    struct CoordinatorConfig {
        // flag to enable/disable the use of reasonableGasPrice.
        bool useReasonableGasPrice;
        // Reentrancy protection.
        bool reentrancyLock;
        // Emergency pause flag
        bool paused;
        // Premium percentage charged.
        uint8 premiumPercentage;
        // Penalty in percent (max 100) for unused gas in an allowance.
        uint8 unusedGasPenaltyPercent;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Estimated gas cost for a beacon fulfillment.
        uint32 redeemableRequestGasOverhead;
        // Estimated gas cost for a callback fulfillment (excludes gas allowance).
        uint32 callbackRequestGasOverhead;
        // reasonableGasPriceStalenessBlocks is how long before we consider
        // the last reported average gas price to be valid before falling back to
        // tx.gasprice.
        uint32 reasonableGasPriceStalenessBlocks;
        // Fallback LINK/ETH ratio.
        uint96 fallbackWeiPerUnitLink;
    }

    // TODO(coventry): There is scope for optimization of the calldata gas cost,
    // here. The solidity lists can be replaced by something lower-level, where
    // the lengths are represented by something shorter, and there could be a
    // specialized part of the report which deals with fulfillments for blocks
    // which have already had their seeds reported.
    struct VRFOutput {
        uint64 blockHeight; // Beacon height this output corresponds to
        uint24 confirmationDelay; // #blocks til offchain system response
        // VRF output for blockhash at blockHeight. If this is (0,0), indicates that
        // this is a request for callbacks for a pre-existing height, and the seed
        // should be sought from contract storage
        ECCArithmetic.G1Point vrfOutput;
        CostedCallback[] callbacks; // Contracts to callback with random outputs
    }

    struct OutputServed {
        uint64 height;
        uint24 confirmationDelay;
        uint256 proofG1X;
        uint256 proofG1Y;
    }

    /// @dev Emitted when randomness is requested without a callback, for the
    /// @dev given beacon height. This signals to the offchain system that it
    /// @dev should provide the VRF output for that height
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    /// @param costJuels the cost in Juels of the randomness request
    event RandomnessRequested(
        uint256 indexed requestID,
        address requester,
        uint64 nextBeaconOutputHeight,
        uint24 confDelay,
        uint256 subID,
        uint16 numWords,
        uint256 costJuels,
        uint256 newSubBalance
    );

    /// @dev Emitted when randomness is redeemed.
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    event RandomnessRedeemed(
        uint256 indexed requestID,
        address indexed requester,
        uint256 subID
    );

    /// @dev Emitted when randomness is requested with a callback, for the given
    /// @dev height, to the given address, which should contain a contract with a
    /// @dev fulfillRandomness(uint256,uint256,bytes) method. This will be
    /// @dev called with the given uint256, the uint256 output, and the given
    /// @dev bytes arguments.
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    /// @param gasAllowance max gas offered to callback method during fulfillment
    /// @param gasPrice tx.gasprice during request
    /// @param weiPerUnitLink ETH/LINK ratio during request
    /// @param arguments callback arguments passed in from consumer contract
    /// @param costJuels the cost in Juels of the randomness request, pre-refund
    event RandomnessFulfillmentRequested(
        uint256 indexed requestID,
        address requester,
        uint64 nextBeaconOutputHeight,
        uint24 confDelay,
        uint256 subID,
        uint16 numWords,
        uint32 gasAllowance,
        uint256 gasPrice,
        uint256 weiPerUnitLink,
        bytes arguments,
        uint256 costJuels,
        uint256 newSubBalance
    );

    /// @notice emitted when the requestIDs have been fulfilled
    ///
    /// @dev There is one entry in truncatedErrorData for each false entry in
    /// @dev successfulFulfillment
    ///
    /// @param requestIDs the IDs of the requests which have been fulfilled
    /// @param successfulFulfillment ith entry true if ith fulfillment succeeded
    /// @param truncatedErrorData ith entry is error message for ith failure
    event RandomWordsFulfilled(
        uint256[] requestIDs,
        bytes successfulFulfillment,
        bytes[] truncatedErrorData,
        uint96[] subBalances,
        uint256[] subIDs
    );

    event OutputsServed(
        uint64 recentBlockHeight,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
        OutputServed[] outputsServed
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ArbSys} from "./vendor/nitro/207827de97/contracts/src/precompiles/ArbSys.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);
    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            if ((getBlockNumber() - blockNumber) > 256) {
                return "";
            }
            return ARBSYS.arbBlockHash(blockNumber);
        }
        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockNumber();
        }
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";

abstract contract IVRFCoordinatorConsumer is OwnerIsCreator {
    IVRFMigratableCoordinator internal s_coordinator;

    constructor(address _coordinator) {
        s_coordinator = IVRFMigratableCoordinator(_coordinator);
    }

    event CoordinatorUpdated(address indexed coordinator);

    error MustBeOwnerOrCoordinator();

    // setCoordinator is called by the current coordinator during migration
    function setCoordinator(address coordinator) external {
        if (msg.sender != owner() && msg.sender != address(s_coordinator)) {
            revert MustBeOwnerOrCoordinator();
        }
        s_coordinator = IVRFMigratableCoordinator(coordinator);
        emit CoordinatorUpdated(coordinator);
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual;

    error MustBeCoordinator();

    function rawFulfillRandomWords(
        uint256 requestID,
        uint256[] memory randomWords,
        bytes memory arguments
    ) external {
        if (address(s_coordinator) != msg.sender) {
            revert MustBeCoordinator();
        }
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 internal constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 internal constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 internal constant Q =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    struct G1Point {
        uint256[2] p;
    }

    struct G2Point {
        uint256[4] p;
    }

    function checkPointOnCurve(G1Point memory p) internal pure {
        require(p.p[0] < P, "x not in F_P");
        require(p.p[1] < P, "y not in F_P");
        uint256 rhs = addmod(
            mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P),
            B,
            P
        );
        require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
    }

    function _addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory sum)
    {
        checkPointOnCurve(p1);
        checkPointOnCurve(p2);

        uint256[4] memory summands;
        summands[0] = p1.p[0];
        summands[1] = p1.p[1];
        summands[2] = p2.p[0];
        summands[3] = p2.p[1];
        uint256[2] memory result;
        uint256 callresult;
        assembly {
            // solhint-disable-line no-inline-assembly
            callresult := staticcall(
                // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
                // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
                150,
                // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
                0x6,
                summands, // input
                0x80, // input length: 4 words
                result, // output
                0x40 // output length: 2 words
            )
        }
        require(callresult != 0, "addg1 call failed");
        sum.p[0] = result[0];
        sum.p[1] = result[1];
        return sum;
    }

    function addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory)
    {
        G1Point memory sum = _addG1(p1, p2);
        // This failure is mathematically possible from a legitimate return
        // value, but vanishingly unlikely, and almost certainly instead
        // reflects a failure in the precompile.
        require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
        return sum;
    }

    // Coordinates for generator of G2.
    uint256 internal constant G2_GEN_X_A =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 internal constant G2_GEN_X_B =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 internal constant G2_GEN_Y_A =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 internal constant G2_GEN_Y_B =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 internal constant PAIRING_GAS_COST = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 internal constant PAIRING_PRECOMPILE_ADDRESS = 0x8;
    uint256 internal constant PAIRING_INPUT_LENGTH = 12 * 0x20;
    uint256 internal constant PAIRING_OUTPUT_LENGTH = 0x20;

    // discreteLogsMatch returns true iff signature = sk*base, where sk is the
    // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
    //
    // This is used for signature/VRF verification. In actual use, g1Base is the
    // hash-to-curve to be signed/exponentiated, and pubkey is the public key
    // the signature pertains to.
    function discreteLogsMatch(
        G1Point memory g1Base,
        G1Point memory signature,
        G2Point memory pubkey
    ) internal view returns (bool) {
        // It is not necessary to check that the points are in their respective
        // groups; the pairing check fails if that's not the case.

        // Let g1, g2 be the canonical generators of G1, G2, respectively..
        // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
        //
        // In the happy path, the result of the first pairing in the following
        // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
        // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
        // terms will cancel, and the pairing function will return one. See
        // EIP-197.
        G1Point[] memory g1s = new G1Point[](2);
        G2Point[] memory g2s = new G2Point[](2);
        g1s[0] = G1Point([g1Base.p[0], P - g1Base.p[1]]);
        g1s[1] = signature;
        g2s[0] = pubkey;
        g2s[1] = G2Point([G2_GEN_X_A, G2_GEN_X_B, G2_GEN_Y_A, G2_GEN_Y_B]);
        return pairing(g1s, g2s);
    }

    function negateG1(G1Point memory p)
        internal
        pure
        returns (G1Point memory neg)
    {
        neg.p[0] = p.p[0];
        neg.p[1] = P - p.p[1];
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    //
    // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].p[0];
            input[i * 6 + 1] = p1[i].p[1];
            input[i * 6 + 2] = p2[i].p[0];
            input[i * 6 + 3] = p2[i].p[1];
            input[i * 6 + 4] = p2[i].p[2];
            input[i * 6 + 5] = p2[i].p[3];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(
                PAIRING_GAS_COST,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success);
        return out[0] != 0;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract IVRFMigratableCoordinator {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        bytes memory extraArgs
    ) external payable virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice rawFulfillRandomness(bytes32,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    ///
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external payable virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @param extraArgs extra arguments
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(
        uint256 subID,
        uint256 requestID,
        bytes memory extraArgs
    ) external virtual returns (uint256[] memory randomness);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness price
    /// @param subID subscription ID
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFee(uint256 subID, bytes memory extraArgs)
        external
        view
        virtual
        returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness fulfillment price
    /// @param subID subscription ID
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFulfillmentFee(
        uint256 subID,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /**
     * @notice Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /**
     * @notice Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Get the current owner
     */
    function owner() public view override returns (address) {
        return s_owner;
    }

    /**
     * @notice validate, transfer ownership, and emit relevant events
     */
    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /**
     * @notice validate access
     */
    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /**
     * @notice Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}