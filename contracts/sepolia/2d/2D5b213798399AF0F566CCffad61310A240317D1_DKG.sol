// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DKGClient.sol";
import "./KeyDataStruct.sol";
import "./vendor/ocr2-contracts/OCR2Abstract.sol";
import "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";

contract DKG is KeyDataStruct, OCR2Abstract, OwnerIsCreator {
    // keyIDClients lists the client contracts which must be contacted when a new
    // key is requested for a given keyID, or when the key is provided. These
    // lists are adjusted using addClient and removeClient.
    mapping(bytes32 => DKGClient[]) s_keyIDClients; /* keyID */

    mapping(bytes32 => mapping(bytes32 => KeyData)) s_keys; /* keyID */ /* config digest */

    // _report stores the key data from a report, and reports it via an event.
    //
    // See golang contract.KeyData#Marshal and contract.Unmarshal for format.
    function _report(
        bytes32 configDigest,
        uint40 epochAndRound,
        bytes memory report
    ) internal {
        bytes32 keyID;
        bytes memory key;
        bytes32[] memory hashes;
        (keyID, key, hashes) = abi.decode(report, (bytes32, bytes, bytes32[]));
        KeyData memory kd = KeyData(key, hashes);

        DKGClient[] memory clients = s_keyIDClients[keyID];
        for (uint256 i = 0; i < clients.length; i++) {
            try clients[i].keyGenerated(kd) {} catch (bytes memory errorData) {
                emit DKGClientError(clients[i], errorData);
            }
        }

        s_keys[keyID][configDigest] = kd;

        // If offchain processes were listening for this event, we could get rid of
        // the above storage, but for now that's a micro-optimization.
        emit KeyGenerated(configDigest, keyID, kd);

        // See, e.g.
        // https://github.com/smartcontractkit/offchain-reporting/blob/28dd19OffchainAggregator.sol#L343
        s_epochOfLastReport = uint32(epochAndRound >> 8);
    }

    // KeyGenerated is emmitted when a key is reported for the given configDigest/processID.
    event KeyGenerated(
        bytes32 indexed configDigest,
        bytes32 indexed keyID,
        KeyData key
    );

    event DKGClientError(DKGClient client, bytes errorData);

    function getKey(bytes32 _keyID, bytes32 _configDigest)
        external
        view
        returns (KeyData memory)
    {
        return s_keys[_keyID][_configDigest];
    }

    // addClient will add the given clientAddress to the list of clients which
    // should be updated when new key information is available for the given keyID
    function addClient(bytes32 keyID, DKGClient clientAddress)
        external
        onlyOwner
    {
        s_keyIDClients[keyID].push(clientAddress);
    }

    // removeClient removes all instances of clientAddress from the list for the
    // given keyID.
    function removeClient(bytes32 keyID, DKGClient clientAddress)
        external
        onlyOwner
    {
        DKGClient[] memory clients = s_keyIDClients[keyID];

        // Potentially overlong list with all instances of clientAddress removed
        DKGClient[] memory newClients = new DKGClient[](clients.length);
        uint256 found;
        for (uint256 i = 0; i < clients.length; i++) {
            if (clients[i] != clientAddress) {
                newClients[i - found] = clientAddress;
            } else {
                found++;
            }
        }

        // List of correct length with clientAddress removed. Could just bash the
        // length of newClients in assembly, instead, if this is too inefficient.
        DKGClient[] memory finalClients = new DKGClient[](
            clients.length - found
        );
        for (uint256 i = 0; i < clients.length - found; i++) {
            finalClients[i] = newClients[i];
        }
        s_keyIDClients[keyID] = finalClients;
    }

    error InvalidOnchainConfigLength(
        uint8 expectedLength,
        uint256 actualLength
    );
    error KeyIDCopyFailed();

    // _afterSetConfig reports that a new key for the given keyID (encoded as the
    // only contents of the _onchainConfig) has been requested, via an event
    // emmission.
    function _afterSetConfig(
        uint8, /* _f */
        bytes memory _onchainConfig,
        bytes32 _configDigest
    ) internal {
        // convert _onchainConfig bytes to bytes32
        bytes32 keyID;
        bytes32 zero;
        if (_onchainConfig.length != 32) {
            revert InvalidOnchainConfigLength(32, _onchainConfig.length);
        }
        assembly {
            keyID := mload(add(_onchainConfig, 0x20))
        }
        if (keyID == zero) {
            revert KeyIDCopyFailed();
        }

        KeyData memory zeroKey;
        s_keys[keyID][_configDigest] = zeroKey;

        DKGClient[] memory clients = s_keyIDClients[keyID];
        for (uint256 i = 0; i < clients.length; i++) {
            clients[i].newKeyRequested();
        }
    }

    // Following methods are mostly cribbed from OCR2Base.sol

    function _beforeSetConfig(uint8 _f, bytes memory _onchainConfig) internal {}

    function _payTransmitter(uint32 initialGas, address transmitter) internal {}

    function typeAndVersion() external pure override returns (string memory) {
        return "DKG 0.0.1";
    }

    uint32 internal s_epochOfLastReport; // epoch at the time of the last-reported distributed key

    uint256 private constant UINT32_MAX = (1 << 32) - 1;

    // Storing these fields used on the hot path in a ConfigInfo variable reduces the
    // retrieval of all of them to a single SLOAD. If any further fields are
    // added, make sure that storage of the struct still takes at most 32 bytes.
    struct ConfigInfo {
        bytes32 latestConfigDigest;
        uint8 f;
        uint8 n;
    }
    ConfigInfo internal s_configInfo;

    // incremented each time a new config is posted. This count is incorporated
    // into the config digest, to prevent replay attacks.
    uint32 internal s_configCount;
    uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems
    // to extract config from logs.
    // Used for s_oracles[a].role, where a is an address, to track the purpose
    // of the address, or to indicate that the address is unset.
    enum Role {
        // No oracle role has been set for address a
        Unset,
        // Signing address for the s_oracles[a].index'th oracle. I.e., report
        // signatures from this oracle should ecrecover back to address a.
        Signer,
        // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
        // report is received by OCR2Aggregator.transmit in which msg.sender is
        // a, it is attributed to the s_oracles[a].index'th oracle.
        Transmitter
    }

    struct Oracle {
        uint8 index; // Index of oracle in s_signers/s_transmitters
        Role role; // Role of the address which mapped to this struct
    }

    mapping(address => Oracle) /* signer OR transmitter address */
        internal s_oracles;

    // s_signers contains the signing address of each oracle
    address[] internal s_signers;

    // s_transmitters contains the transmission address of each oracle,
    // i.e. the address the oracle actually sends transactions to the contract from
    address[] internal s_transmitters;

    function latestConfigDigestAndEpoch()
        external
        view
        override
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        )
    {
        return (false, s_configInfo.latestConfigDigest, s_epochOfLastReport);
    }

    function latestConfigDetails()
        external
        view
        override
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        )
    {
        return (
            s_configCount,
            s_latestConfigBlockNumber,
            s_configInfo.latestConfigDigest
        );
    }

    struct SetConfigArgs {
        address[] signers;
        address[] transmitters;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }

    error TooManyOracles(uint8 maxOracles, uint256 providedOracles);
    error NumberOfFaultyOraclesTooHigh(
        uint8 numFaultyOracles,
        uint256 numSigners
    );
    error IncorrectNumberOfFaultyOracles();
    error RepeatedSigner(address repeatedSignerAddress);
    error RepeatedTransmitter(address repeatedTransmitterAddress);
    error SignersTransmittersMismatch(
        uint256 numSigners,
        uint256 numTransmitters
    );

    modifier checkConfigValid(
        uint256 _numSigners,
        uint256 _numTransmitters,
        uint8 _f
    ) {
        if (_numSigners > MAX_NUM_ORACLES) {
            revert TooManyOracles(uint8(MAX_NUM_ORACLES), _numSigners);
        }
        if (_numSigners != _numTransmitters) {
            revert SignersTransmittersMismatch(_numSigners, _numTransmitters);
        }
        if (_numSigners <= 3 * _f) {
            revert NumberOfFaultyOraclesTooHigh(_f, _numSigners);
        }
        if (_f == 0) {
            revert IncorrectNumberOfFaultyOracles();
        }
        _;
    }

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param _signers addresses with which oracles sign the reports
     * @param _transmitters addresses oracles use to transmit the reports
     * @param _f number of faulty oracles the system can tolerate
     * @param _onchainConfig encoded on-chain contract configuration
     * @param _offchainConfigVersion version number for offchainEncoding schema
     * @param _offchainConfig encoded off-chain oracle configuration
     */
    function setConfig(
        address[] memory _signers,
        address[] memory _transmitters,
        uint8 _f,
        bytes memory _onchainConfig,
        uint64 _offchainConfigVersion,
        bytes memory _offchainConfig
    )
        external
        override
        checkConfigValid(_signers.length, _transmitters.length, _f)
        onlyOwner
    {
        SetConfigArgs memory args = SetConfigArgs({
            signers: _signers,
            transmitters: _transmitters,
            f: _f,
            onchainConfig: _onchainConfig,
            offchainConfigVersion: _offchainConfigVersion,
            offchainConfig: _offchainConfig
        });

        _beforeSetConfig(args.f, args.onchainConfig);

        while (s_signers.length != 0) {
            // remove any old signer/transmitter addresses
            uint256 lastIdx = s_signers.length - 1;
            address signer = s_signers[lastIdx];
            address transmitter = s_transmitters[lastIdx];
            delete s_oracles[signer];
            delete s_oracles[transmitter];
            s_signers.pop();
            s_transmitters.pop();
        }

        for (uint256 i = 0; i < args.signers.length; i++) {
            // add new signer/transmitter addresses
            if (s_oracles[args.signers[i]].role != Role.Unset) {
                revert RepeatedSigner(args.signers[i]);
            }
            s_oracles[args.signers[i]] = Oracle(uint8(i), Role.Signer);
            if (s_oracles[args.transmitters[i]].role != Role.Unset) {
                revert RepeatedTransmitter(args.transmitters[i]);
            }
            s_oracles[args.transmitters[i]] = Oracle(
                uint8(i),
                Role.Transmitter
            );
            s_signers.push(args.signers[i]);
            s_transmitters.push(args.transmitters[i]);
        }
        s_configInfo.f = args.f;
        uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
        s_latestConfigBlockNumber = uint32(ChainSpecificUtil.getBlockNumber());
        s_configCount += 1;
        bytes32 lcd;
        {
            lcd = configDigestFromConfigData(
                block.chainid,
                address(this),
                s_configCount,
                args.signers,
                args.transmitters,
                args.f,
                args.onchainConfig,
                args.offchainConfigVersion,
                args.offchainConfig
            );
            s_configInfo.latestConfigDigest = lcd;
        }
        s_configInfo.n = uint8(args.signers.length);

        emit ConfigSet(
            previousConfigBlockNumber,
            s_configInfo.latestConfigDigest,
            s_configCount,
            args.signers,
            args.transmitters,
            args.f,
            args.onchainConfig,
            args.offchainConfigVersion,
            args.offchainConfig
        );

        _afterSetConfig(args.f, args.onchainConfig, lcd);
    }

    function configDigestFromConfigData(
        uint256 _chainId,
        address _contractAddress,
        uint64 _configCount,
        address[] memory _signers,
        address[] memory _transmitters,
        uint8 _f,
        bytes memory _onchainConfig,
        uint64 _encodedConfigVersion,
        bytes memory _encodedConfig
    ) internal pure returns (bytes32) {
        uint256 h = uint256(
            keccak256(
                abi.encode(
                    _chainId,
                    _contractAddress,
                    _configCount,
                    _signers,
                    _transmitters,
                    _f,
                    _onchainConfig,
                    _encodedConfigVersion,
                    _encodedConfig
                )
            )
        );
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    // The constant-length components of the msg.data sent to transmit.
    // See the "If we wanted to call sam" example on for example reasoning
    // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
    uint16 constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
        4 + // function selector
            32 *
            3 + // 3 words containing reportContext
            32 + // word containing start location of abiencoded report value
            32 + // word containing location start of abiencoded rs value
            32 + // word containing start location of abiencoded ss value
            32 + // rawVs value
            32 + // word containing length of report
            32 + // word containing length rs
            32 + // word containing length of ss
            0; // placeholder

    error CalldataLengthMismatch(uint256 expectedLength, uint256 actualLength);

    function requireExpectedMsgDataLength(
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private pure {
        // calldata will never be big enough to make this overflow
        uint256 expected = uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
            report.length + // one byte per entry in _report
            rs.length *
            32 + // 32 bytes per entry in _rs
            ss.length *
            32 + // 32 bytes per entry in _ss
            0; // placeholder
        if (msg.data.length != expected) {
            revert CalldataLengthMismatch(expected, msg.data.length);
        }
    }

    error ConfigDigestMismatch(bytes32 expected, bytes32 actual);

    /**
     * @notice transmit is called to post a new report to the contract
     * @param report serialized report, which the signatures are signing.
     * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
     * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
     * @param rawVs ith element is the the V component of the ith signature
     */
    function transmit(
        // NOTE: If these parameters are changed, expectedMsgDataLength and/or
        // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs // signatures
    ) external override {
        uint256 initialGas = gasleft(); // This line must come first

        {
            // reportContext consists of:
            // reportContext[0]: ConfigDigest
            // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
            // reportContext[2]: ExtraHash
            bytes32 configDigest = reportContext[0];
            uint40 epochAndRound = uint40(uint256(reportContext[1]));

            _report(configDigest, epochAndRound, report);

            emit Transmitted(configDigest, uint32(epochAndRound >> 8));

            ConfigInfo memory configInfo = s_configInfo;
            if (configInfo.latestConfigDigest != configDigest) {
                revert ConfigDigestMismatch(
                    configInfo.latestConfigDigest,
                    configDigest
                );
            }

            requireExpectedMsgDataLength(report, rs, ss);
            _requireValidSignatures(
                reportContext,
                report,
                rs,
                ss,
                rawVs,
                configInfo
            );
        }

        assert(initialGas < UINT32_MAX);
        _payTransmitter(uint32(initialGas), msg.sender);
    }

    error InvalidTransmitter(address transmitter);
    error InvalidSigner(address signer);
    error NonUniqueSignature();
    error IncorrectNumberOfSignatures(
        uint256 expectedNumSignatures,
        uint256 rsLength,
        uint256 ssLength
    );

    function _requireValidSignatures(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs, // signatures
        ConfigInfo memory configInfo
    ) internal virtual {
        {
            uint256 expectedNumSignatures = (configInfo.n + configInfo.f) /
                2 +
                1; // require unique answer
            // require(rs.length == expectedNumSignatures, "wrong number of signatures");
            bytes memory numsigs = new bytes(1);
            numsigs[0] = bytes1(uint8(expectedNumSignatures));
            if (rs.length != expectedNumSignatures || rs.length != ss.length) {
                revert IncorrectNumberOfSignatures(
                    expectedNumSignatures,
                    rs.length,
                    ss.length
                );
            }

            Oracle memory transmitter = s_oracles[msg.sender];
            // Check that sender is authorized to report
            if (
                transmitter.role != Role.Transmitter ||
                msg.sender != s_transmitters[transmitter.index]
            ) {
                revert InvalidTransmitter(msg.sender);
            }
        }

        {
            // Verify signatures attached to report
            bytes32 h = keccak256(
                abi.encodePacked(keccak256(report), reportContext)
            );
            bool[MAX_NUM_ORACLES] memory signed;

            Oracle memory o;
            for (uint256 i = 0; i < rs.length; i++) {
                address signer = ecrecover(
                    h,
                    uint8(rawVs[i]) + 27,
                    rs[i],
                    ss[i]
                );
                o = s_oracles[signer];
                if (o.role != Role.Signer) {
                    revert InvalidSigner(signer);
                }
                if (signed[o.index]) {
                    revert NonUniqueSignature();
                }
                signed[o.index] = true;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./KeyDataStruct.sol";

// DKGClient's are called when there is new information about the keyID they are
// associated with.
//
// WARNING: IMPLEMENTATIONS **MUST** CHECK THAT CALLS COME FROM THE EXPECTED DKG CONTRACT
interface DKGClient is KeyDataStruct {
    // newKeyRequested is called when a new key is requested for the given keyID,
    // on the DKG contract.
    function newKeyRequested() external;

    // keyGenerated is called when key data for given keyID is reported on the DKG
    // contract.
    function keyGenerated(KeyData memory kd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface KeyDataStruct {
    struct KeyData {
        bytes publicKey; // distrbuted key
        bytes32[] hashes; // hashes of shares used to construct key
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/TypeAndVersionInterface.sol";

abstract contract OCR2Abstract is TypeAndVersionInterface {
    // Maximum number of oracles the offchain reporting protocol is designed for
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /**
     * @notice triggers a new run of the offchain reporting protocol
     * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
     * @param configDigest configDigest of this configuration
     * @param configCount ordinal number of this config setting among all config settings over the life of this contract
     * @param signers ith element is address ith oracle uses to sign a report
     * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
     * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    event ConfigSet(
        uint32 previousConfigBlockNumber,
        bytes32 configDigest,
        uint64 configCount,
        address[] signers,
        address[] transmitters,
        uint8 f,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param signers addresses with which oracles sign the reports
     * @param transmitters addresses oracles use to transmit the reports
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    function setConfig(
        address[] memory signers,
        address[] memory transmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external virtual;

    /**
     * @notice information about current offchain reporting protocol configuration
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
     */
    function latestConfigDetails()
        external
        view
        virtual
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        );

    function _configDigestFromConfigData(
        uint256 chainId,
        address contractAddress,
        uint64 configCount,
        address[] memory signers,
        address[] memory transmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) internal pure returns (bytes32) {
        uint256 h = uint256(
            keccak256(
                abi.encode(
                    chainId,
                    contractAddress,
                    configCount,
                    signers,
                    transmitters,
                    f,
                    onchainConfig,
                    offchainConfigVersion,
                    offchainConfig
                )
            )
        );
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    /**
  * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
    event Transmitted(bytes32 configDigest, uint32 epoch);

    /**
   * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
    function latestConfigDigestAndEpoch()
        external
        view
        virtual
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        );

    /**
     * @notice transmit is called to post a new report to the contract
     * @param report serialized report, which the signatures are signing.
     * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
     * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
     * @param rawVs ith element is the the V component of the ith signature
     */
    function transmit(
        // NOTE: If these parameters are changed, expectedMsgDataLength and/or
        // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs // signatures
    ) external virtual;
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
pragma solidity ^0.8.0;

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
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